package controller;

import dao.*;
import model.*;
import util.AuditLogger;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.*;
import java.io.IOException;
import java.util.List;
import java.util.stream.Collectors;

@WebServlet("/BookAppointmentServlet")
public class BookAppointmentServlet extends HttpServlet {

    private final AppointmentDAO appointmentDAO = new AppointmentDAO();
    private final DoctorDAO      doctorDAO      = new DoctorDAO();
    private final PatientDAO     patientDAO     = new PatientDAO();

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse res)
            throws ServletException, IOException {
        User user = getPatientUser(req, res);
        if (user == null) return;

        Patient patient = patientDAO.getPatientByUserId(user.getUserId());
        
        // CHECK MEDICAL AID STATUS BEFORE SHOWING BOOKING PAGE
        if (patient != null) {
            String membershipStatus = patient.getMembershipStatus();
            if (membershipStatus == null) {
                membershipStatus = "pending";
            }
            
            if (!"active".equalsIgnoreCase(membershipStatus)) {
                // Patient cannot book - redirect to profile with error
                String errorMsg = "Your medical aid is " + membershipStatus.toUpperCase() + 
                                 ". Please update your medical aid details before booking appointments.";
                req.setAttribute("error", errorMsg);
                req.setAttribute("membershipStatus", membershipStatus);
                req.getRequestDispatcher("/patient/profile.jsp").forward(req, res);
                return;
            }
        }

        List<Doctor> allDoctors = doctorDAO.getAllDoctors();

        List<Doctor> availableDoctors = allDoctors.stream()
                .filter(d -> d.getSchedule() != null && !d.getSchedule().isEmpty())
                .collect(Collectors.toList());

        req.setAttribute("doctors", availableDoctors);
        req.getRequestDispatcher("/patient/bookAppointment.jsp").forward(req, res);
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse res)
            throws ServletException, IOException {

        User user = getPatientUser(req, res);
        if (user == null) return;

        Patient patient = patientDAO.getPatientByUserId(user.getUserId());
        if (patient == null) {
            res.sendRedirect(req.getContextPath() + "/patient/bookAppointment.jsp?error=Patient+profile+not+found.");
            return;
        }
        
        // CHECK MEDICAL AID STATUS AGAIN BEFORE BOOKING
        String membershipStatus = patient.getMembershipStatus();
        if (membershipStatus == null) {
            membershipStatus = "pending";
        }
        
        if (!"active".equalsIgnoreCase(membershipStatus)) {
            String errorMsg = "Cannot book appointment. Your medical aid status is " + 
                             membershipStatus.toUpperCase() + ". Please update your details first.";
            res.sendRedirect(req.getContextPath() + "/patient/profile.jsp?error=" + errorMsg);
            return;
        }

        int    doctorId = parseInt(req.getParameter("doctorId"), -1);
        String date     = req.getParameter("appointmentDate");
        String time     = req.getParameter("appointmentTime");
        String notes    = req.getParameter("notes");

        if (doctorId == -1 || isEmpty(date) || isEmpty(time)) {
            res.sendRedirect(req.getContextPath() + "/patient/bookAppointment.jsp?error=Doctor,+date+and+time+are+required.");
            return;
        }

        if (!doctorDAO.isDoctorAvailable(doctorId, date, time)) {
            res.sendRedirect(req.getContextPath() + "/patient/bookAppointment.jsp?error=That+time+slot+is+already+taken.");
            return;
        }

        Appointment apt = new Appointment();
        apt.setPatientId(patient.getPatientId());
        apt.setDoctorId(doctorId);
        apt.setAppointmentDate(date);
        apt.setAppointmentTime(time);
        apt.setNotes(notes);
        apt.setValidationStatus("pending");

        boolean booked = appointmentDAO.bookAppointment(apt);

        if (!booked) {
            res.sendRedirect(req.getContextPath() + "/patient/bookAppointment.jsp?error=Booking+failed.+Please+try+again.");
            return;
        }

        AuditLogger.log(user.getUserId(), "BOOK_APPOINTMENT",
                "Appointment #" + apt.getAppointmentId() + " booked",
                req.getRemoteAddr());

        res.sendRedirect(req.getContextPath() + "/patient/myAppointments.jsp?success=Appointment+booked+successfully!");
    }

    private User getPatientUser(HttpServletRequest req, HttpServletResponse res)
            throws IOException {
        HttpSession session = req.getSession(false);
        if (session == null) { res.sendRedirect(req.getContextPath() + "/login.jsp"); return null; }
        User user = (User) session.getAttribute("user");
        if (user == null || !"patient".equals(user.getRole())) {
            res.sendRedirect(req.getContextPath() + "/login.jsp");
            return null;
        }
        return user;
    }

    private int parseInt(String s, int def) {
        try { return Integer.parseInt(s); } catch (Exception e) { return def; }
    }

    private boolean isEmpty(String s) {
        return s == null || s.trim().isEmpty();
    }
}