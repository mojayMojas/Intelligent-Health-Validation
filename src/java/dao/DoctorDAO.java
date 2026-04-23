package dao;

import model.Doctor;
import model.DoctorSchedule;
import util.DBConnection;

import java.sql.*;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

public class DoctorDAO {

    // ==================== CREATE ====================

    public boolean createDoctor(int userId, String specialization, double fee) {
        String sql = "INSERT INTO doctors (user_id, specialization, consultation_fee) VALUES (?, ?, ?)";
        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setInt(1, userId);
            ps.setString(2, specialization);
            ps.setDouble(3, fee);
            return ps.executeUpdate() > 0;
        } catch (SQLException e) {
            System.err.println("Error creating doctor: " + e.getMessage());
            e.printStackTrace();
        }
        return false;
    }

    // ==================== READ ====================

    public Doctor getDoctorByUserId(int userId) {
        if (userId <= 0) return null;
        String sql = "SELECT d.*, u.username, u.full_name, u.email, u.phone, u.role " +
                     "FROM doctors d JOIN users u ON d.user_id = u.user_id WHERE d.user_id = ?";
        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setInt(1, userId);
            ResultSet rs = ps.executeQuery();
            if (rs.next()) {
                Doctor d = mapRow(rs);
                d.setSchedule(getDoctorSchedule(d.getDoctorId()));
                return d;
            }
        } catch (SQLException e) { e.printStackTrace(); }
        return null;
    }

    public Doctor getDoctorById(int doctorId) {
        if (doctorId <= 0) return null;
        String sql = "SELECT d.*, u.username, u.full_name, u.email, u.phone, u.role " +
                     "FROM doctors d JOIN users u ON d.user_id = u.user_id WHERE d.doctor_id = ?";
        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setInt(1, doctorId);
            ResultSet rs = ps.executeQuery();
            if (rs.next()) {
                Doctor d = mapRow(rs);
                d.setSchedule(getDoctorSchedule(d.getDoctorId()));
                return d;
            }
        } catch (SQLException e) { e.printStackTrace(); }
        return null;
    }

    /**
     * FIX: Was doing 1 query per doctor to load schedule (N+1 problem).
     * Now uses 2 queries total regardless of how many doctors exist:
     *   1. Fetch all doctors
     *   2. Fetch ALL schedules at once, then assign in memory
     */
    public List<Doctor> getAllDoctors() {
        List<Doctor> list = new ArrayList<>();
        String sql = "SELECT d.*, u.username, u.full_name, u.email, u.phone, u.role " +
                     "FROM doctors d JOIN users u ON d.user_id = u.user_id ORDER BY u.full_name";

        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {

            ResultSet rs = ps.executeQuery();
            Map<Integer, Doctor> doctorMap = new HashMap<>();
            while (rs.next()) {
                Doctor d = mapRow(rs);
                list.add(d);
                doctorMap.put(d.getDoctorId(), d);
            }

            if (!list.isEmpty()) {
                // Load ALL schedules in one query and distribute in memory
                loadSchedulesInto(con, doctorMap);
            }

        } catch (SQLException e) { e.printStackTrace(); }
        return list;
    }

    /**
     * Fetches every row from doctor_schedule in a single query and assigns
     * each schedule entry to the matching Doctor object in the map.
     */
    private void loadSchedulesInto(Connection con, Map<Integer, Doctor> doctorMap) {
        String sql = "SELECT * FROM doctor_schedule " +
                     "ORDER BY doctor_id, " +
                     "CASE day_of_week " +
                     "WHEN 'Monday' THEN 1 WHEN 'Tuesday' THEN 2 WHEN 'Wednesday' THEN 3 " +
                     "WHEN 'Thursday' THEN 4 WHEN 'Friday' THEN 5 " +
                     "WHEN 'Saturday' THEN 6 WHEN 'Sunday' THEN 7 ELSE 8 END";
        try (PreparedStatement ps = con.prepareStatement(sql)) {
            ResultSet rs = ps.executeQuery();
            while (rs.next()) {
                int docId = rs.getInt("doctor_id");
                Doctor d = doctorMap.get(docId);
                if (d == null) continue;

                DoctorSchedule ds = new DoctorSchedule();
                ds.setScheduleId(rs.getInt("schedule_id"));
                ds.setDoctorId(docId);
                ds.setDayOfWeek(rs.getString("day_of_week"));
                ds.setStartTime(rs.getString("start_time"));
                ds.setEndTime(rs.getString("end_time"));

                if (d.getSchedule() == null) d.setSchedule(new ArrayList<>());
                d.getSchedule().add(ds);
            }
        } catch (SQLException e) { e.printStackTrace(); }
    }

    // ==================== UPDATE ====================

    public boolean updateDoctorProfile(int doctorId, String specialization, double fee) {
        return updateDoctorProfile(doctorId, specialization, null, fee);
    }

    public boolean updateDoctorProfile(int doctorId, String specialization,
                                       String qualification, double fee) {
        String sql = "UPDATE doctors SET specialization=?, qualification=?, consultation_fee=? " +
                     "WHERE doctor_id=?";
        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setString(1, specialization);
            ps.setString(2, qualification != null ? qualification : "MBChB");
            ps.setDouble(3, fee);
            ps.setInt(4, doctorId);
            return ps.executeUpdate() > 0;
        } catch (SQLException e) { e.printStackTrace(); }
        return false;
    }

    // ==================== SCHEDULE ====================

    public List<DoctorSchedule> getDoctorSchedule(int doctorId) {
        List<DoctorSchedule> list = new ArrayList<>();
        String sql = "SELECT * FROM doctor_schedule WHERE doctor_id = ? " +
                     "ORDER BY CASE day_of_week " +
                     "WHEN 'Monday' THEN 1 WHEN 'Tuesday' THEN 2 WHEN 'Wednesday' THEN 3 " +
                     "WHEN 'Thursday' THEN 4 WHEN 'Friday' THEN 5 " +
                     "WHEN 'Saturday' THEN 6 WHEN 'Sunday' THEN 7 ELSE 8 END";
        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setInt(1, doctorId);
            ResultSet rs = ps.executeQuery();
            while (rs.next()) {
                DoctorSchedule ds = new DoctorSchedule();
                ds.setScheduleId(rs.getInt("schedule_id"));
                ds.setDoctorId(rs.getInt("doctor_id"));
                ds.setDayOfWeek(rs.getString("day_of_week"));
                ds.setStartTime(rs.getString("start_time"));
                ds.setEndTime(rs.getString("end_time"));
                list.add(ds);
            }
        } catch (SQLException e) { e.printStackTrace(); }
        return list;
    }

    public boolean addSchedule(int doctorId, String dayOfWeek, String startTime, String endTime) {
        String sql = "INSERT INTO doctor_schedule (doctor_id, day_of_week, start_time, end_time) " +
                     "VALUES (?, ?, ?, ?)";
        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setInt(1, doctorId);
            ps.setString(2, dayOfWeek);
            ps.setString(3, startTime);
            ps.setString(4, endTime);
            return ps.executeUpdate() > 0;
        } catch (SQLException e) { e.printStackTrace(); }
        return false;
    }

    public boolean removeSchedule(int scheduleId) {
        String sql = "DELETE FROM doctor_schedule WHERE schedule_id = ?";
        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setInt(1, scheduleId);
            return ps.executeUpdate() > 0;
        } catch (SQLException e) { e.printStackTrace(); }
        return false;
    }

    // ==================== AVAILABILITY ====================

    public boolean isDoctorAvailable(int doctorId, String date, String time) {
        String sql = "SELECT COUNT(*) FROM appointments a " +
                     "JOIN appointment_status s ON a.status_id = s.status_id " +
                     "WHERE a.doctor_id = ? AND a.appointment_date = ? AND a.appointment_time = ? " +
                     "AND s.status_name NOT IN ('cancelled', 'no-show')";
        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setInt(1, doctorId);
            ps.setString(2, date);
            ps.setString(3, time);
            ResultSet rs = ps.executeQuery();
            if (rs.next()) return rs.getInt(1) == 0;
        } catch (SQLException e) { e.printStackTrace(); }
        return false;
    }
    
    
    // Add these methods to your existing DoctorDAO.java file

/**
 * Delete doctor schedule
 */
public boolean deleteDoctorSchedule(int doctorId) {
    String sql = "DELETE FROM doctor_schedule WHERE doctor_id = ?";
    try (Connection conn = DBConnection.getConnection();
         PreparedStatement ps = conn.prepareStatement(sql)) {
        ps.setInt(1, doctorId);
        ps.executeUpdate();
        return true;
    } catch (SQLException e) {
        e.printStackTrace();
        return false;
    }
}

/**
 * Delete a doctor record
 */
public boolean deleteDoctor(int doctorId) {
    String sql = "DELETE FROM doctors WHERE doctor_id = ?";
    try (Connection conn = DBConnection.getConnection();
         PreparedStatement ps = conn.prepareStatement(sql)) {
        ps.setInt(1, doctorId);
        return ps.executeUpdate() > 0;
    } catch (SQLException e) {
        e.printStackTrace();
        return false;
    }
}

/**
 * Get doctor by user ID
 */


    // ==================== STATS ====================

    public int getTotalDoctorCount() {
        String sql = "SELECT COUNT(*) FROM doctors";
        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {
            ResultSet rs = ps.executeQuery();
            if (rs.next()) return rs.getInt(1);
        } catch (SQLException e) { e.printStackTrace(); }
        return 0;
    }

    public int getDoctorAppointmentCount(int doctorId) {
        String sql = "SELECT COUNT(*) FROM appointments WHERE doctor_id = ?";
        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setInt(1, doctorId);
            ResultSet rs = ps.executeQuery();
            if (rs.next()) return rs.getInt(1);
        } catch (SQLException e) { e.printStackTrace(); }
        return 0;
    }

    // ==================== HELPER ====================

    private Doctor mapRow(ResultSet rs) throws SQLException {
        Doctor d = new Doctor();
        d.setDoctorId(rs.getInt("doctor_id"));
        d.setUserId(rs.getInt("user_id"));
        d.setSpecialization(rs.getString("specialization"));
        d.setConsultationFee(rs.getDouble("consultation_fee"));
        try { d.setQualification(rs.getString("qualification")); } catch (SQLException ignored) {}
        d.setUsername(rs.getString("username"));
        d.setFullName(rs.getString("full_name"));
        d.setEmail(rs.getString("email"));
        d.setPhone(rs.getString("phone"));
        d.setRole(rs.getString("role"));
        d.setAvailableDays("Mon,Tue,Wed,Thu,Fri");
        d.setAvailableTime("09:00-17:00");
        d.setAvailable(true);
        return d;
    }
}
