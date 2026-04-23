package controller;

import dao.PatientDAO;
import dao.UserDAO;
import model.Patient;
import model.User;
import util.AuditLogger;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.*;
import java.io.IOException;

@WebServlet("/PatientServlet")
public class PatientServlet extends HttpServlet {

    private final PatientDAO patientDAO = new PatientDAO();
    private final UserDAO    userDAO    = new UserDAO();

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse res)
            throws ServletException, IOException {

        HttpSession session = req.getSession(false);
        User user = session != null ? (User) session.getAttribute("user") : null;
        if (user == null || !"patient".equals(user.getRole())) {
            res.sendRedirect(req.getContextPath() + "/login.jsp"); 
            return;
        }

        String action = req.getParameter("action");

        if ("updateProfile".equals(action)) {
            user.setFullName(req.getParameter("fullName"));
            user.setEmail(req.getParameter("email"));
            user.setPhone(req.getParameter("phone"));
            boolean ok = userDAO.updateUser(user);
            if (ok) session.setAttribute("user", user);
            AuditLogger.log(user.getUserId(), "UPDATE_PROFILE", "Patient profile updated", req.getRemoteAddr());
            redirect(res, req, "/patient/profile.jsp", ok ? "Profile updated." : null, ok ? null : "Update failed.");

        } else if ("updateMedicalAid".equals(action)) {
            Patient patient = patientDAO.getPatientByUserId(user.getUserId());
            if (patient == null) { 
                redirect(res, req, "/patient/profile.jsp", null, "Patient not found."); 
                return; 
            }
            String provider = req.getParameter("medicalAidProvider");
            String number   = req.getParameter("medicalAidNumber");
            
            // FIX: updateMedicalAid now only takes 3 parameters (no status)
            boolean ok = patientDAO.updateMedicalAid(patient.getPatientId(), provider, number);
            
            if (ok) {
                // Recalculate PRI after medical aid update
                patientDAO.recalculatePRI(patient.getPatientId());
            }
            
            AuditLogger.log(user.getUserId(), "UPDATE_MEDICAL_AID", "Provider=" + provider, req.getRemoteAddr());
            redirect(res, req, "/patient/profile.jsp", ok ? "Medical aid updated." : null, ok ? null : "Update failed.");

        } else {
            res.sendRedirect(req.getContextPath() + "/patient/profile.jsp");
        }
    }

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse res)
            throws ServletException, IOException { 
        doPost(req, res); 
    }

    private void redirect(HttpServletResponse res, HttpServletRequest req,
                          String path, String success, String error) throws IOException {
        String url = req.getContextPath() + path + "?";
        if (success != null) url += "success=" + success.replace(" ", "+");
        if (error   != null) url += "error="   + error.replace(" ", "+");
        res.sendRedirect(url);
    }
}