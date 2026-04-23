package controller;

import dao.AppointmentDAO;
import model.Appointment;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.*;
import java.io.IOException;
import java.io.PrintWriter;
import java.sql.*;
import java.util.HashSet;
import java.util.Set;
import util.DBConnection;

@WebServlet("/CheckAvailabilityServlet")
public class CheckAvailabilityServlet extends HttpServlet {

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse res)
            throws ServletException, IOException {
        
        res.setContentType("application/json");
        res.setCharacterEncoding("UTF-8");
        
        // Enable CORS for local development
        res.setHeader("Access-Control-Allow-Origin", "*");
        
        int doctorId = -1;
        String doctorIdParam = req.getParameter("doctorId");
        String date = req.getParameter("date");
        
        try {
            doctorId = Integer.parseInt(doctorIdParam);
        } catch (NumberFormatException e) {
            doctorId = -1;
        }
        
        System.out.println("CheckAvailabilityServlet - doctorId: " + doctorId + ", date: " + date);
        
        StringBuilder json = new StringBuilder();
        json.append("{");
        json.append("\"availableSlots\":[");
        
        if (doctorId != -1 && date != null && !date.isEmpty()) {
            try {
                // OPTIMIZED: Query only booked slots for this specific doctor and date
                // Instead of loading ALL appointments into memory
                Set<String> bookedSlots = getBookedSlots(doctorId, date);
                
                // Define all possible time slots
                String[] allSlots = {"09:00", "09:30", "10:00", "10:30", "11:00", "11:30", 
                                     "12:00", "14:00", "14:30", "15:00", "15:30", "16:00", "16:30"};
                
                boolean first = true;
                for (String slot : allSlots) {
                    if (!bookedSlots.contains(slot)) {
                        if (!first) json.append(",");
                        json.append("\"").append(slot).append("\"");
                        first = false;
                    }
                }
            } catch (Exception e) {
                System.out.println("Error checking availability: " + e.getMessage());
                e.printStackTrace();
            }
        }
        
        json.append("]");
        json.append("}");
        
        System.out.println("Response: " + json.toString());
        
        PrintWriter out = res.getWriter();
        out.print(json.toString());
        out.flush();
    }
    
    /**
     * Optimized method that only queries booked slots for a specific doctor and date
     * instead of loading all appointments into memory.
     */
    private Set<String> getBookedSlots(int doctorId, String date) {
        Set<String> bookedSlots = new HashSet<>();
        
        String sql = "SELECT a.appointment_time FROM appointments a " +
                     "JOIN appointment_status s ON a.status_id = s.status_id " +
                     "WHERE a.doctor_id = ? AND a.appointment_date = ? " +
                     "AND s.status_name NOT IN ('cancelled', 'no-show')";
        
        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {
            
            ps.setInt(1, doctorId);
            ps.setString(2, date);
            
            ResultSet rs = ps.executeQuery();
            while (rs.next()) {
                String aptTime = rs.getString("appointment_time");
                if (aptTime != null) {
                    // Normalize time format
                    if (aptTime.length() > 5) {
                        aptTime = aptTime.substring(0, 5);
                    }
                    bookedSlots.add(aptTime);
                    System.out.println("Booked slot: " + aptTime);
                }
            }
            
        } catch (SQLException e) {
            System.err.println("Error querying booked slots: " + e.getMessage());
            e.printStackTrace();
        }
        
        return bookedSlots;
    }
}