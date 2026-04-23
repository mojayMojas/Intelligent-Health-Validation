package util;

import java.sql.*;
import java.time.LocalDateTime;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

/**
 * Writes entries to the audit_log table.
 *
 * FIX: Logging is now done on a background thread so it never blocks
 * the servlet request thread. If the log write fails it prints to
 * stderr — audit failures are non-fatal.
 */
public class AuditLogger {

    // Single background thread dedicated to audit writes
    private static final ExecutorService writer =
            Executors.newSingleThreadExecutor(r -> {
                Thread t = new Thread(r, "AuditLogger");
                t.setDaemon(true); // won't prevent app shutdown
                return t;
            });

    public static void log(int userId, String action, String details, String ipAddress) {
        // Fire-and-forget: submit to background thread, return immediately
        writer.submit(() -> writeLog(userId, action, details, ipAddress));
    }

    public static void log(String action, String details, String ipAddress) {
        log(0, action, details, ipAddress);
    }

    private static void writeLog(int userId, String action, String details, String ipAddress) {
        String sql = "INSERT INTO audit_log (user_id, action, details, ip_address, timestamp) VALUES (?,?,?,?,?)";
        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {

            ps.setInt(1, userId);
            ps.setString(2, truncate(action, 100));
            ps.setString(3, truncate(details, 500));
            ps.setString(4, truncate(ipAddress, 45));
            ps.setTimestamp(5, Timestamp.valueOf(LocalDateTime.now()));
            ps.executeUpdate();

        } catch (SQLException e) {
            System.err.println("[AuditLogger] Failed to write log: " + e.getMessage());
        }
    }

    private static String truncate(String value, int maxLength) {
        if (value == null) return null;
        return value.length() > maxLength ? value.substring(0, maxLength) : value;
    }
}
