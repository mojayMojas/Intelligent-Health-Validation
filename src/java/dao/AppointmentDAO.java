package dao;

import model.Appointment;
import model.Reminder;
import util.DBConnection;

import java.sql.*;
import java.time.LocalTime;
import java.util.ArrayList;
import java.util.List;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

public class AppointmentDAO {

    // Background executor for async medical aid validation
    private static final ExecutorService validationExecutor = 
        Executors.newFixedThreadPool(5);
    
    private static final ExecutorService reminderExecutor = 
        Executors.newSingleThreadExecutor();

    // ------------------------------------------------------------------
    // Booking - Now returns immediately, validation happens in background
    // ------------------------------------------------------------------
    public boolean bookAppointment(Appointment apt) {
        Connection con = null;
        try {
            con = DBConnection.getConnection();
            con.setAutoCommit(false);
            
            // Get status_id for 'pending'
            int statusId = getStatusId(con, "pending");
            
            // Insert appointment first (without waiting for validation)
            String sql = "INSERT INTO appointments (patient_id, doctor_id, status_id, " +
                         "appointment_date, appointment_time, validation_status, notes) " +
                         "VALUES (?,?,?,?,?,?,?)";
            
            try (PreparedStatement ps = con.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS)) {
                ps.setInt(1, apt.getPatientId());
                ps.setInt(2, apt.getDoctorId());
                ps.setInt(3, statusId);
                ps.setString(4, apt.getAppointmentDate());
                ps.setString(5, apt.getAppointmentTime());
                ps.setString(6, "pending");  // Initially pending validation
                ps.setString(7, apt.getNotes());
                
                int rows = ps.executeUpdate();
                if (rows > 0) {
                    ResultSet keys = ps.getGeneratedKeys();
                    if (keys.next()) {
                        int newId = keys.getInt(1);
                        apt.setAppointmentId(newId);
                    }
                    
                    // Increment total appointments count
                    PatientDAO pDAO = new PatientDAO();
                    pDAO.incrementTotalAppointments(apt.getPatientId());
                    
                    con.commit();
                    
                    // ASYNC: Validate medical aid in background (doesn't block response)
                    validateMedicalAidAsync(apt.getAppointmentId(), apt.getPatientId());
                    
                    // ASYNC: Create reminders in background
                    createRemindersAsync(apt);
                    
                    return true;
                }
            }
            con.rollback();
            return false;
        } catch (SQLException e) { 
            try { if (con != null) con.rollback(); } catch (SQLException ex) {}
            e.printStackTrace(); 
            return false;
        } finally {
            try { if (con != null) con.setAutoCommit(true); } catch (SQLException e) {}
            DBConnection.close(con, null, null);
        }
    }
    
    private void validateMedicalAidAsync(int appointmentId, int patientId) {
        validationExecutor.submit(() -> {
            try {
                MedicalAidDAO maDAO = new MedicalAidDAO();
                boolean isValid = maDAO.validateMedicalAid(patientId, appointmentId);
                String newValStatus = isValid ? "approved" : "rejected";
                updateValidationStatus(appointmentId, newValStatus);
                System.out.println("[Async] Medical aid validation completed for appt #" + appointmentId + ": " + newValStatus);
            } catch (Exception e) {
                System.err.println("[Async] Medical aid validation failed for appt #" + appointmentId + ": " + e.getMessage());
                updateValidationStatus(appointmentId, "rejected");
            }
        });
    }
    
    private void createRemindersAsync(Appointment apt) {
        reminderExecutor.submit(() -> {
            try {
                ReminderDAO reminderDAO = new ReminderDAO();
                
                // Create 24h reminder
                Reminder reminder24h = new Reminder();
                reminder24h.setAppointmentId(apt.getAppointmentId());
                reminder24h.setReminderType("24h");
                reminder24h.setChannel("email");
                reminder24h.setStatus("pending");
                reminder24h.setScheduledTime(calculateReminderTime(apt.getAppointmentDate(), apt.getAppointmentTime(), -24));
                reminderDAO.createReminder(reminder24h);
                
                // Create 1h reminder
                Reminder reminder1h = new Reminder();
                reminder1h.setAppointmentId(apt.getAppointmentId());
                reminder1h.setReminderType("1h");
                reminder1h.setChannel("email");
                reminder1h.setStatus("pending");
                reminder1h.setScheduledTime(calculateReminderTime(apt.getAppointmentDate(), apt.getAppointmentTime(), -1));
                reminderDAO.createReminder(reminder1h);
                
                System.out.println("[Async] Reminders created for appt #" + apt.getAppointmentId());
            } catch (Exception e) {
                System.err.println("[Async] Failed to create reminders for appt #" + apt.getAppointmentId() + ": " + e.getMessage());
            }
        });
    }
    
    private String calculateReminderTime(String date, String time, int hoursOffset) {
        try {
            java.text.SimpleDateFormat sdf = new java.text.SimpleDateFormat("yyyy-MM-dd HH:mm");
            java.util.Date appointmentDate = sdf.parse(date + " " + time);
            long reminderTime = appointmentDate.getTime() + (hoursOffset * 60 * 60 * 1000L);
            return new java.text.SimpleDateFormat("yyyy-MM-dd HH:mm:ss").format(new java.util.Date(reminderTime));
        } catch (Exception e) {
            return date + " " + time;
        }
    }

    // Helper to get status ID from status name
    private int getStatusId(Connection con, String statusName) throws SQLException {
        String sql = "SELECT status_id FROM appointment_status WHERE status_name = ?";
        try (PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setString(1, statusName);
            ResultSet rs = ps.executeQuery();
            if (rs.next()) return rs.getInt(1);
        }
        return 1; // Default to pending
    }

    private String getStatusName(Connection con, int statusId) throws SQLException {
        String sql = "SELECT status_name FROM appointment_status WHERE status_id = ?";
        try (PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setInt(1, statusId);
            ResultSet rs = ps.executeQuery();
            if (rs.next()) return rs.getString(1);
        }
        return "unknown";
    }
    
    public boolean rescheduleAppointment(int appointmentId, String newDate, String newTime, String reason) {
        String sql = "UPDATE appointments SET appointment_date=?, appointment_time=?, status_id=?, cancellation_reason=? WHERE appointment_id=?";
        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {
            int rescheduledId = getStatusId(con, "rescheduled");
            ps.setString(1, newDate);
            ps.setString(2, newTime);
            ps.setInt(3, rescheduledId);
            ps.setString(4, reason);
            ps.setInt(5, appointmentId);
            return ps.executeUpdate() > 0;
        } catch (SQLException e) { e.printStackTrace(); }
        return false;
    }

    // ------------------------------------------------------------------
    // Fetch appointments - OPTIMIZED queries
    // ------------------------------------------------------------------
    public List<Appointment> getAppointmentsByPatient(int patientId) {
        List<Appointment> list = new ArrayList<>();
        
        if (patientId <= 0) {
            System.err.println("Invalid patient ID: " + patientId);
            return list;
        }
        
        String sql = "SELECT a.*, s.status_name, " +
                     "p.patient_id, pu.full_name as patient_name, " +
                     "d.doctor_id, du.full_name as doctor_name, " +
                     "p.medical_aid_provider, p.reliability_score " +
                     "FROM appointments a " +
                     "JOIN appointment_status s ON a.status_id = s.status_id " +
                     "LEFT JOIN patients p ON a.patient_id = p.patient_id " +
                     "LEFT JOIN users pu ON p.user_id = pu.user_id " +
                     "LEFT JOIN doctors d ON a.doctor_id = d.doctor_id " +
                     "LEFT JOIN users du ON d.user_id = du.user_id " +
                     "WHERE a.patient_id = ? " +
                     "ORDER BY a.appointment_date DESC, a.appointment_time DESC";
        
        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {
            
            ps.setInt(1, patientId);
            ResultSet rs = ps.executeQuery();
            
            while (rs.next()) {
                list.add(mapRow(rs));
            }
            
        } catch (SQLException e) { 
            System.err.println("SQL Error in getAppointmentsByPatient: " + e.getMessage());
            e.printStackTrace(); 
        }
        
        return list;
    }

    public List<Appointment> getAppointmentsByDoctor(int doctorId) {
        List<Appointment> list = new ArrayList<>();
        
        String sql = "SELECT a.*, s.status_name, " +
                     "p.patient_id, pu.full_name as patient_name, " +
                     "d.doctor_id, du.full_name as doctor_name " +
                     "FROM appointments a " +
                     "JOIN appointment_status s ON a.status_id = s.status_id " +
                     "LEFT JOIN patients p ON a.patient_id = p.patient_id " +
                     "LEFT JOIN users pu ON p.user_id = pu.user_id " +
                     "LEFT JOIN doctors d ON a.doctor_id = d.doctor_id " +
                     "LEFT JOIN users du ON d.user_id = du.user_id " +
                     "WHERE a.doctor_id = ? " +
                     "ORDER BY a.appointment_date ASC, a.appointment_time ASC";
        
        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setInt(1, doctorId);
            ResultSet rs = ps.executeQuery();
            while (rs.next()) list.add(mapRow(rs));
        } catch (SQLException e) { e.printStackTrace(); }
        return list;
    }

    public List<Appointment> getAllAppointments() {
        List<Appointment> list = new ArrayList<>();
        
        String sql = "SELECT a.*, s.status_name, " +
                     "p.patient_id, pu.full_name as patient_name, " +
                     "d.doctor_id, du.full_name as doctor_name " +
                     "FROM appointments a " +
                     "JOIN appointment_status s ON a.status_id = s.status_id " +
                     "LEFT JOIN patients p ON a.patient_id = p.patient_id " +
                     "LEFT JOIN users pu ON p.user_id = pu.user_id " +
                     "LEFT JOIN doctors d ON a.doctor_id = d.doctor_id " +
                     "LEFT JOIN users du ON d.user_id = du.user_id " +
                     "ORDER BY a.appointment_date DESC, a.appointment_time DESC " +
                     "FETCH FIRST 500 ROWS ONLY"; // Limit to prevent memory issues
        
        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {
            ResultSet rs = ps.executeQuery();
            while (rs.next()) list.add(mapRow(rs));
        } catch (SQLException e) { e.printStackTrace(); }
        return list;
    }

    public List<Appointment> getPendingValidations() {
        List<Appointment> list = new ArrayList<>();
        
        String sql = "SELECT a.*, s.status_name, " +
                     "p.patient_id, pu.full_name as patient_name, " +
                     "d.doctor_id, du.full_name as doctor_name " +
                     "FROM appointments a " +
                     "JOIN appointment_status s ON a.status_id = s.status_id " +
                     "LEFT JOIN patients p ON a.patient_id = p.patient_id " +
                     "LEFT JOIN users pu ON p.user_id = pu.user_id " +
                     "LEFT JOIN doctors d ON a.doctor_id = d.doctor_id " +
                     "LEFT JOIN users du ON d.user_id = du.user_id " +
                     "WHERE a.validation_status = 'pending' " +
                     "ORDER BY a.appointment_date ASC " +
                     "FETCH FIRST 100 ROWS ONLY"; // Limit pending validations
        
        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {
            ResultSet rs = ps.executeQuery();
            while (rs.next()) list.add(mapRow(rs));
        } catch (SQLException e) { e.printStackTrace(); }
        return list;
    }

    public Appointment getAppointmentById(int id) {
        String sql = "SELECT a.*, s.status_name, " +
                     "p.patient_id, pu.full_name as patient_name, " +
                     "d.doctor_id, du.full_name as doctor_name " +
                     "FROM appointments a " +
                     "JOIN appointment_status s ON a.status_id = s.status_id " +
                     "LEFT JOIN patients p ON a.patient_id = p.patient_id " +
                     "LEFT JOIN users pu ON p.user_id = pu.user_id " +
                     "LEFT JOIN doctors d ON a.doctor_id = d.doctor_id " +
                     "LEFT JOIN users du ON d.user_id = du.user_id " +
                     "WHERE a.appointment_id = ?";
        
        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setInt(1, id);
            ResultSet rs = ps.executeQuery();
            if (rs.next()) return mapRow(rs);
        } catch (SQLException e) { e.printStackTrace(); }
        return null;
    }

    // ------------------------------------------------------------------
    // Status updates
    // ------------------------------------------------------------------
    public boolean updateStatus(int appointmentId, String statusName) {
        Connection con = null;
        try {
            con = DBConnection.getConnection();
            con.setAutoCommit(false);
            
            int statusId = getStatusId(con, statusName);
            
            String sql = "UPDATE appointments SET status_id=? WHERE appointment_id=?";
            try (PreparedStatement ps = con.prepareStatement(sql)) {
                ps.setInt(1, statusId);
                ps.setInt(2, appointmentId);
                int result = ps.executeUpdate();
                
                if (result > 0) {
                    // Update patient counters based on status
                    Appointment apt = getAppointmentById(appointmentId);
                    if (apt != null) {
                        PatientDAO pDAO = new PatientDAO();
                        switch (statusName) {
                            case "completed":
                                pDAO.incrementCompletedCount(apt.getPatientId());
                                break;
                            case "no-show":
                                pDAO.incrementNoShowCount(apt.getPatientId());
                                break;
                            case "cancelled":
                                pDAO.incrementCancellationCount(apt.getPatientId());
                                break;
                        }
                        // Recalculate PRI asynchronously
                        recalculatePRIAsync(apt.getPatientId());
                    }
                }
                
                con.commit();
                return result > 0;
            }
        } catch (SQLException e) { 
            try { if (con != null) con.rollback(); } catch (SQLException ex) {}
            e.printStackTrace(); 
        } finally {
            try { if (con != null) con.setAutoCommit(true); } catch (SQLException e) {}
            DBConnection.close(con, null, null);
        }
        return false;
    }
    
    private void recalculatePRIAsync(int patientId) {
        validationExecutor.submit(() -> {
            try {
                PatientDAO pDAO = new PatientDAO();
                pDAO.recalculatePRI(patientId);
            } catch (Exception e) {
                System.err.println("Failed to recalculate PRI for patient " + patientId + ": " + e.getMessage());
            }
        });
    }

    public boolean updateValidationStatus(int appointmentId, String validationStatus) {
        String sql = "UPDATE appointments SET validation_status=?, validation_timestamp=CURRENT_TIMESTAMP WHERE appointment_id=?";
        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setString(1, validationStatus);
            ps.setInt(2, appointmentId);
            return ps.executeUpdate() > 0;
        } catch (SQLException e) { e.printStackTrace(); }
        return false;
    }

    public boolean cancelAppointment(int appointmentId, String reason) {
        String sql = "UPDATE appointments SET status_id=?, cancellation_reason=? WHERE appointment_id=?";
        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {
            int cancelledId = getStatusId(con, "cancelled");
            ps.setInt(1, cancelledId);
            ps.setString(2, reason);
            ps.setInt(3, appointmentId);
            return ps.executeUpdate() > 0;
        } catch (SQLException e) { e.printStackTrace(); }
        return false;
    }

    // ------------------------------------------------------------------
    // Analytics
    // ------------------------------------------------------------------
    public int countByStatus(String statusName) {
        String sql = "SELECT COUNT(*) FROM appointments a " +
                     "JOIN appointment_status s ON a.status_id = s.status_id " +
                     "WHERE s.status_name=?";
        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setString(1, statusName);
            ResultSet rs = ps.executeQuery();
            if (rs.next()) return rs.getInt(1);
        } catch (SQLException e) { e.printStackTrace(); }
        return 0;
    }

    public int countTotal() {
        String sql = "SELECT COUNT(*) FROM appointments";
        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {
            ResultSet rs = ps.executeQuery();
            if (rs.next()) return rs.getInt(1);
        } catch (SQLException e) { e.printStackTrace(); }
        return 0;
    }

    public int countByDate(String date) {
        String sql = "SELECT COUNT(*) FROM appointments WHERE appointment_date = ?";
        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setString(1, date);
            ResultSet rs = ps.executeQuery();
            if (rs.next()) return rs.getInt(1);
        } catch (SQLException e) { e.printStackTrace(); }
        return 0;
    }
    
    // Add these methods to your AppointmentDAO.java file

/**
 * Delete all appointments for a patient
 */
public boolean deleteAppointmentsByPatient(int patientId) {
    String sql = "DELETE FROM appointments WHERE patient_id = ?";
    try (Connection con = DBConnection.getConnection();
         PreparedStatement ps = con.prepareStatement(sql)) {
        ps.setInt(1, patientId);
        int rows = ps.executeUpdate();
        System.out.println("Deleted " + rows + " appointments for patient ID: " + patientId);
        return true;
    } catch (SQLException e) {
        System.err.println("Error deleting appointments for patient: " + e.getMessage());
        e.printStackTrace();
        return false;
    }
}

/**
 * Delete all appointments for a doctor
 */
public boolean deleteAppointmentsByDoctor(int doctorId) {
    String sql = "DELETE FROM appointments WHERE doctor_id = ?";
    try (Connection con = DBConnection.getConnection();
         PreparedStatement ps = con.prepareStatement(sql)) {
        ps.setInt(1, doctorId);
        int rows = ps.executeUpdate();
        System.out.println("Deleted " + rows + " appointments for doctor ID: " + doctorId);
        return true;
    } catch (SQLException e) {
        System.err.println("Error deleting appointments for doctor: " + e.getMessage());
        e.printStackTrace();
        return false;
    }
}

    // ------------------------------------------------------------------
    private Appointment mapRow(ResultSet rs) throws SQLException {
        Appointment a = new Appointment();
        a.setAppointmentId(rs.getInt("appointment_id"));
        a.setPatientId(rs.getInt("patient_id"));
        a.setDoctorId(rs.getInt("doctor_id"));
        a.setStatusId(rs.getInt("status_id"));
        a.setPatientName(rs.getString("patient_name"));
        a.setDoctorName(rs.getString("doctor_name"));
        a.setAppointmentDate(rs.getString("appointment_date"));
        a.setAppointmentTime(rs.getString("appointment_time"));
        
        try {
            a.setStatus(rs.getString("status_name"));
        } catch (SQLException e) {
            a.setStatus("unknown");
        }
        
        a.setValidationStatus(rs.getString("validation_status"));
        a.setValidationTimestamp(rs.getString("validation_timestamp"));
        a.setCancellationReason(rs.getString("cancellation_reason"));
        a.setNotes(rs.getString("notes"));
        
        a.setReminder24hSent(rs.getInt("reminder_24h_sent") == 1);
        a.setReminder1hSent(rs.getInt("reminder_1h_sent") == 1);
        
        try { a.setPatientEmail(rs.getString("patient_email")); } catch (SQLException ignored) {}
        try { a.setPatientPhone(rs.getString("patient_phone")); } catch (SQLException ignored) {}
        try { a.setMedicalAidProvider(rs.getString("medical_aid_provider")); } catch (SQLException ignored) {}
        try { a.setReliabilityScore(rs.getInt("reliability_score")); } catch (SQLException ignored) {}
        
        return a;
    }
}