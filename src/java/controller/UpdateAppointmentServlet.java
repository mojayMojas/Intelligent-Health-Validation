package controller;

import dao.AppointmentDAO;
import dao.PatientDAO;
import model.Appointment;
import model.User;
import util.AuditLogger;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.*;
import java.io.IOException;

@WebServlet("/UpdateAppointmentServlet")
public class UpdateAppointmentServlet extends HttpServlet {

    private final AppointmentDAO appointmentDAO = new AppointmentDAO();
    private final PatientDAO patientDAO = new PatientDAO();

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse res)
            throws ServletException, IOException {

        HttpSession session = req.getSession(false);
        User user = session != null ? (User) session.getAttribute("user") : null;
        if (user == null) {
            res.sendRedirect(req.getContextPath() + "/login.jsp");
            return;
        }

        String action = req.getParameter("action");
        int apptId = parseInt(req.getParameter("id"), -1);

        if (apptId == -1 || action == null) {
            res.sendRedirect(req.getContextPath() + "/index.jsp");
            return;
        }

        boolean ok = false;
        Appointment apt = appointmentDAO.getAppointmentById(apptId);

        switch (action) {
            case "confirm":
                ok = appointmentDAO.updateStatus(apptId, "confirmed");
                break;
            case "complete":
                ok = appointmentDAO.updateStatus(apptId, "completed");
                if (ok && apt != null) {
                    patientDAO.incrementCompletedCount(apt.getPatientId());
                    patientDAO.recalculatePRI(apt.getPatientId());
                }
                break;
            case "cancel":
                ok = appointmentDAO.updateStatus(apptId, "cancelled");
                if (ok && apt != null) {
                    patientDAO.incrementCancellationCount(apt.getPatientId());
                    patientDAO.recalculatePRI(apt.getPatientId());
                }
                break;
            case "no-show":
                ok = appointmentDAO.updateStatus(apptId, "no-show");
                if (ok && apt != null) {
                    patientDAO.incrementNoShowCount(apt.getPatientId());
                    patientDAO.recalculatePRI(apt.getPatientId());
                }
                break;
            default:
                ok = false;
        }

        AuditLogger.log(user.getUserId(), "UPDATE_APPOINTMENT",
                "Appointment #" + apptId + " action=" + action + " ok=" + ok,
                req.getRemoteAddr());

        String redirectPath = getRedirectPath(user.getRole());
        String param = ok ? "?success=Status+updated" : "?error=Update+failed";
        res.sendRedirect(req.getContextPath() + redirectPath + param);
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse res)
            throws ServletException, IOException {
        doGet(req, res);
    }

    private String getRedirectPath(String role) {
        switch (role) {
            case "doctor":
                return "/doctor/manageAppointments.jsp";
            case "patient":
                return "/patient/myAppointments.jsp";
            case "admin":
                return "/admin/appointments.jsp";
            default:
                return "/index.jsp";
        }
    }

    private int parseInt(String s, int def) {
        try {
            return Integer.parseInt(s);
        } catch (Exception e) {
            return def;
        }
    }
}