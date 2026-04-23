package dao;

import model.MedicalAidProvider;
import model.ValidationLog;
import util.DBConnection;

import java.sql.*;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

public class MedicalAidDAO {

    // ------------------------------------------------------------------
    // Validate a patient's medical aid
    // Returns true if membership_status = 'active'
    // ------------------------------------------------------------------
    public boolean validateMedicalAid(int patientId, int appointmentId) {
        String sql = "SELECT p.membership_status, p.medical_aid_provider, p.medical_aid_number, " +
                     "       mp.provider_id " +
                     "FROM patients p " +
                     "LEFT JOIN medical_aid_providers mp ON mp.provider_name = p.medical_aid_provider " +
                     "WHERE p.patient_id = ?";
        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setInt(1, patientId);
            ResultSet rs = ps.executeQuery();
            if (rs.next()) {
                String membershipStatus = rs.getString("membership_status");
                boolean valid = "active".equalsIgnoreCase(membershipStatus);
                String msg = valid ? "Membership active and verified." : "Membership status: " + membershipStatus;
                // Log the validation attempt
                insertValidationRecord(con, patientId, rs.getInt("provider_id"), appointmentId,
                        valid ? "approved" : "rejected", rs.getString("medical_aid_number"), msg);
                return valid;
            }
        } catch (SQLException e) { 
            e.printStackTrace(); 
        }
        return false;
    }
    
    /**
     * Batch validate multiple patients in a single query
     * This fixes the N+1 query problem in AdminServlet
     */
    public Map<Integer, Boolean> batchValidateMedicalAid(List<Integer> patientIds) {
        Map<Integer, Boolean> resultMap = new HashMap<>();
        
        if (patientIds == null || patientIds.isEmpty()) {
            return resultMap;
        }
        
        // Build the IN clause - check for membership_status column
        StringBuilder sql = new StringBuilder();
        sql.append("SELECT p.patient_id");
        
        // Check if membership_status column exists
        boolean hasMembershipStatus = checkColumnExists("patients", "membership_status");
        
        if (hasMembershipStatus) {
            sql.append(", p.membership_status FROM patients p WHERE p.patient_id IN (");
        } else {
            // If membership_status doesn't exist, treat all as active
            sql.append(" FROM patients p WHERE p.patient_id IN (");
        }
        
        for (int i = 0; i < patientIds.size(); i++) {
            if (i > 0) sql.append(",");
            sql.append("?");
        }
        sql.append(")");
        
        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql.toString())) {
            
            // Set parameters
            for (int i = 0; i < patientIds.size(); i++) {
                ps.setInt(i + 1, patientIds.get(i));
            }
            
            ResultSet rs = ps.executeQuery();
            
            if (hasMembershipStatus) {
                while (rs.next()) {
                    int patientId = rs.getInt("patient_id");
                    String membershipStatus = rs.getString("membership_status");
                    boolean isValid = "active".equalsIgnoreCase(membershipStatus);
                    resultMap.put(patientId, isValid);
                }
            } else {
                // No membership_status column, treat all as valid
                while (rs.next()) {
                    int patientId = rs.getInt("patient_id");
                    resultMap.put(patientId, true);
                }
            }
            
            // For patients not found in results, mark as invalid
            for (int patientId : patientIds) {
                if (!resultMap.containsKey(patientId)) {
                    resultMap.put(patientId, false);
                }
            }
            
        } catch (SQLException e) {
            System.err.println("Error in batch validation: " + e.getMessage());
            e.printStackTrace();
            // On error, mark all as invalid
            for (int patientId : patientIds) {
                resultMap.put(patientId, false);
            }
        }
        
        return resultMap;
    }
    
    /**
     * Helper method to check if a column exists in a table
     */
    private boolean checkColumnExists(String tableName, String columnName) {
        try (Connection con = DBConnection.getConnection()) {
            DatabaseMetaData metaData = con.getMetaData();
            try (ResultSet rs = metaData.getColumns(null, null, tableName.toUpperCase(), columnName.toUpperCase())) {
                return rs.next();
            }
        } catch (SQLException e) {
            return false;
        }
    }

    private void insertValidationRecord(Connection con, int patientId, int providerId, int appointmentId,
                                        String status, String memberNumber, String message) {
        String sql = "INSERT INTO validation_log (patient_id, provider_id, appointment_id, validation_result, member_number, response_message, validation_time) " +
                     "VALUES (?,?,?,?,?,?, CURRENT_TIMESTAMP)";
        try (PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setInt(1, patientId);
            if (providerId > 0) ps.setInt(2, providerId); else ps.setNull(2, Types.INTEGER);
            if (appointmentId > 0) ps.setInt(3, appointmentId); else ps.setNull(3, Types.INTEGER);
            ps.setString(4, status);
            ps.setString(5, memberNumber);
            ps.setString(6, message);
            ps.executeUpdate();
        } catch (SQLException e) { e.printStackTrace(); }
    }

    // ------------------------------------------------------------------
    // Providers
    // ------------------------------------------------------------------
    public List<MedicalAidProvider> getAllProviders() {
        List<MedicalAidProvider> list = new ArrayList<>();
        String sql = "SELECT mp.*, u.user_id FROM medical_aid_providers mp " +
                     "LEFT JOIN users u ON mp.user_id = u.user_id WHERE mp.is_active = TRUE";
        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {
            ResultSet rs = ps.executeQuery();
            while (rs.next()) list.add(mapProvider(rs));
        } catch (SQLException e) { e.printStackTrace(); }
        return list;
    }

    public MedicalAidProvider getProviderByUserId(int userId) {
        String sql = "SELECT * FROM medical_aid_providers WHERE user_id = ?";
        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setInt(1, userId);
            ResultSet rs = ps.executeQuery();
            if (rs.next()) return mapProvider(rs);
        } catch (SQLException e) { e.printStackTrace(); }
        return null;
    }

    public MedicalAidProvider getProviderById(int providerId) {
        String sql = "SELECT * FROM medical_aid_providers WHERE provider_id = ?";
        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setInt(1, providerId);
            ResultSet rs = ps.executeQuery();
            if (rs.next()) return mapProvider(rs);
        } catch (SQLException e) { e.printStackTrace(); }
        return null;
    }

    // ------------------------------------------------------------------
    // Validation history
    // ------------------------------------------------------------------
    public List<ValidationLog> getValidationsByProvider(int providerId) {
        List<ValidationLog> list = new ArrayList<>();
        String sql = "SELECT v.*, mp.provider_name, u.full_name FROM validation_log v " +
                     "LEFT JOIN medical_aid_providers mp ON v.provider_id = mp.provider_id " +
                     "LEFT JOIN patients p ON v.patient_id = p.patient_id " +
                     "LEFT JOIN users u ON p.user_id = u.user_id " +
                     "WHERE v.provider_id = ? ORDER BY v.validation_time DESC " +
                     "FETCH FIRST 100 ROWS ONLY";
        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setInt(1, providerId);
            ResultSet rs = ps.executeQuery();
            while (rs.next()) list.add(mapValidation(rs));
        } catch (SQLException e) { e.printStackTrace(); }
        return list;
    }

    public List<ValidationLog> getValidationsByPatient(int patientId) {
        List<ValidationLog> list = new ArrayList<>();
        String sql = "SELECT v.*, mp.provider_name, u.full_name FROM validation_log v " +
                     "LEFT JOIN medical_aid_providers mp ON v.provider_id = mp.provider_id " +
                     "LEFT JOIN patients p ON v.patient_id = p.patient_id " +
                     "LEFT JOIN users u ON p.user_id = u.user_id " +
                     "WHERE v.patient_id = ? ORDER BY v.validation_time DESC " +
                     "FETCH FIRST 100 ROWS ONLY";
        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setInt(1, patientId);
            ResultSet rs = ps.executeQuery();
            while (rs.next()) list.add(mapValidation(rs));
        } catch (SQLException e) { e.printStackTrace(); }
        return list;
    }

    public List<ValidationLog> getAllValidations() {
        List<ValidationLog> list = new ArrayList<>();
        String sql = "SELECT v.*, mp.provider_name, u.full_name FROM validation_log v " +
                     "LEFT JOIN medical_aid_providers mp ON v.provider_id = mp.provider_id " +
                     "LEFT JOIN patients p ON v.patient_id = p.patient_id " +
                     "LEFT JOIN users u ON p.user_id = u.user_id " +
                     "ORDER BY v.validation_time DESC " +
                     "FETCH FIRST 200 ROWS ONLY";
        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {
            ResultSet rs = ps.executeQuery();
            while (rs.next()) list.add(mapValidation(rs));
        } catch (SQLException e) { e.printStackTrace(); }
        return list;
    }

    // ------------------------------------------------------------------
    // Medical Aid registry methods
    // ------------------------------------------------------------------
    public boolean addToMedicalAidRegistry(String providerName, String memberNumber, 
                                           String memberName, String status, 
                                           String planType, String expiryDate) {
        String sql = "INSERT INTO medical_aid (provider_name, member_number, member_name, " +
                     "status, plan_type, expiry_date) VALUES (?,?,?,?,?,?)";
        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setString(1, providerName);
            ps.setString(2, memberNumber);
            ps.setString(3, memberName);
            ps.setString(4, status);
            ps.setString(5, planType);
            ps.setDate(6, expiryDate != null ? Date.valueOf(expiryDate) : null);
            return ps.executeUpdate() > 0;
        } catch (SQLException e) { e.printStackTrace(); }
        return false;
    }

    public boolean checkMedicalAidInRegistry(String providerName, String memberNumber) {
        String sql = "SELECT COUNT(*) FROM medical_aid WHERE provider_name = ? " +
                     "AND member_number = ? AND status = 'active' " +
                     "AND expiry_date >= CURRENT_DATE";
        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setString(1, providerName);
            ps.setString(2, memberNumber);
            ResultSet rs = ps.executeQuery();
            if (rs.next()) {
                return rs.getInt(1) > 0;
            }
        } catch (SQLException e) { e.printStackTrace(); }
        return false;
    }

    // ------------------------------------------------------------------
    // Mapping methods
    // ------------------------------------------------------------------
    private MedicalAidProvider mapProvider(ResultSet rs) throws SQLException {
        MedicalAidProvider p = new MedicalAidProvider();
        p.setProviderId(rs.getInt("provider_id"));
        p.setProviderName(rs.getString("provider_name"));
        p.setContactPerson(rs.getString("contact_person"));
        p.setEmail(rs.getString("email"));
        p.setPhone(rs.getString("phone"));
        p.setActive(rs.getBoolean("is_active"));
        try { p.setUserId(rs.getInt("user_id")); } catch (SQLException ignored) {}
        return p;
    }

    private ValidationLog mapValidation(ResultSet rs) throws SQLException {
        ValidationLog v = new ValidationLog();
        v.setValidationId(rs.getInt("validation_id"));
        v.setPatientId(rs.getInt("patient_id"));
        
        String providerName = rs.getString("provider_name");
        v.setAidProvider(providerName != null ? providerName : "Unknown");
        
        v.setValidationTime(rs.getString("validation_time"));
        v.setValidationResult(rs.getString("validation_result"));
        v.setMemberNumber(rs.getString("member_number"));
        
        try { 
            String patientName = rs.getString("full_name");
            v.setPatientName(patientName);
        } catch (SQLException ignored) {}
        
        return v;
    }
}