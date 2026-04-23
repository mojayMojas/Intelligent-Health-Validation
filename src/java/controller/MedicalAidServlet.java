package controller;

import dao.AppointmentDAO;
import dao.MedicalAidDAO;
import dao.PatientDAO;
import model.Appointment;
import model.MedicalAidProvider;
import model.User;
import model.ValidationLog;
import util.AuditLogger;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.*;
import java.io.IOException;
import java.util.List;

@WebServlet("/MedicalAidServlet")
public class MedicalAidServlet extends HttpServlet {

    private final MedicalAidDAO  medicalAidDAO  = new MedicalAidDAO();
    private final AppointmentDAO appointmentDAO = new AppointmentDAO();
    private final PatientDAO     patientDAO     = new PatientDAO();

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse res)
            throws ServletException, IOException {

        User user = requireMedicalAid(req, res);
        if (user == null) return;

        MedicalAidProvider provider = medicalAidDAO.getProviderByUserId(user.getUserId());
        String action = req.getParameter("action");

        if ("approve".equals(action) || "reject".equals(action)) {
            int appointmentId = parseInt(req.getParameter("appointmentId"), -1);
            int patientId     = parseInt(req.getParameter("patientId"), -1);
            
            if (appointmentId == -1 || patientId == -1) {
                res.sendRedirect(req.getContextPath() + "/medicalaid/validations.jsp?error=Missing+parameters."); 
                return;
            }

            // Get the appointment to check its current status
            Appointment apt = appointmentDAO.getAppointmentById(appointmentId);
            if (apt == null) {
                res.sendRedirect(req.getContextPath() + "/medicalaid/validations.jsp?error=Appointment+not+found.");
                return;
            }

            boolean approved = "approve".equals(action);
            String newValStatus = approved ? "approved" : "rejected";
            
            // Update validation status
            boolean ok = appointmentDAO.updateValidationStatus(appointmentId, newValStatus);

            if (ok && approved) {
                // If approved, update patient's medical aid info if available
                if (apt.getMedicalAidProvider() != null && !apt.getMedicalAidProvider().isEmpty()) {
                    patientDAO.updateMedicalAid(patientId, apt.getMedicalAidProvider(), null);
                }
                // Recalculate PRI after approval
                patientDAO.recalculatePRI(patientId);
            }

            AuditLogger.log(user.getUserId(), "MEDAID_VALIDATE",
                    "apptId=" + appointmentId + " | " + newValStatus + " | ok=" + ok, 
                    req.getRemoteAddr());

            String msg = approved ? "Medical aid approved." : "Medical aid rejected.";
            res.sendRedirect(req.getContextPath() + "/medicalaid/validations.jsp?success=" + msg);
            return;

        } else if ("history".equals(action)) {
            if (provider != null) {
                List<ValidationLog> history = medicalAidDAO.getValidationsByProvider(provider.getProviderId());
                req.setAttribute("validationHistory", history);
                req.getRequestDispatcher("/medicalaid/history.jsp").forward(req, res);
                return;
            }
            res.sendRedirect(req.getContextPath() + "/medicalaid/validations.jsp?error=Provider+not+found.");
            return;

        } else {
            // Default: List pending validations
            List<Appointment> pending = appointmentDAO.getPendingValidations();
            req.setAttribute("pendingAppointments", pending);
            
            if (provider != null) {
                List<ValidationLog> recent = medicalAidDAO.getValidationsByProvider(provider.getProviderId());
                // Limit to 10 most recent
                if (recent != null && recent.size() > 10) {
                    recent = recent.subList(0, 10);
                }
                req.setAttribute("recentValidations", recent);
            }
            
            req.getRequestDispatcher("/medicalaid/validations.jsp").forward(req, res);
            return;
        }
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse res)
            throws ServletException, IOException { 
        doGet(req, res); 
    }

    private User requireMedicalAid(HttpServletRequest req, HttpServletResponse res)
            throws IOException {
        HttpSession session = req.getSession(false);
        if (session == null) {
            res.sendRedirect(req.getContextPath() + "/login.jsp"); 
            return null;
        }
        
        User user = (User) session.getAttribute("user");
        if (user == null || !"medicalaid".equals(user.getRole())) {
            res.sendRedirect(req.getContextPath() + "/login.jsp"); 
            return null;
        }
        return user;
    }

    private int parseInt(String s, int def) {
        try { 
            return Integer.parseInt(s); 
        } catch (Exception e) { 
            return def; 
        }
    }
}