package controller;

import dao.*;
import model.*;
import util.AuditLogger;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.*;
import java.io.IOException;
import java.io.PrintWriter;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

@WebServlet("/AdminServlet")
public class AdminServlet extends HttpServlet {

    private final UserDAO userDAO = new UserDAO();
    private final PatientDAO patientDAO = new PatientDAO();
    private final AppointmentDAO appointmentDAO = new AppointmentDAO();
    private final AuditLogDAO auditLogDAO = new AuditLogDAO();
    private final DoctorDAO doctorDAO = new DoctorDAO();
    private final MedicalAidDAO medicalAidDAO = new MedicalAidDAO();

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse res)
            throws ServletException, IOException {

        User admin = requireAdmin(req, res);
        if (admin == null) return;

        String action = req.getParameter("action");
        String contextPath = req.getContextPath();

        // ==================== USER MANAGEMENT ACTIONS ====================

        if ("deleteUser".equals(action)) {
            int userId = parseInt(req.getParameter("userId"), -1);
            String permanent = req.getParameter("permanent");
            boolean ok = false;

            if (userId != -1) {
                if ("true".equals(permanent)) {
                    ok = deleteUserCompletely(userId);
                    if (ok) {
                        AuditLogger.log(admin.getUserId(), "DELETE_USER_PERMANENT",
                                "Permanently deleted user ID: " + userId,
                                req.getRemoteAddr());
                    }
                    res.sendRedirect(contextPath + "/admin/users.jsp?" +
                            (ok ? "success=User+permanently+deleted." : "error=Delete+failed."));
                } else {
                    ok = userDAO.deactivateUser(userId);
                    AuditLogger.log(admin.getUserId(), "DEACTIVATE_USER",
                            "Deactivated user ID: " + userId,
                            req.getRemoteAddr());
                    res.sendRedirect(contextPath + "/admin/users.jsp?" +
                            (ok ? "success=User+deactivated." : "error=Deactivate+failed."));
                }
            } else {
                res.sendRedirect(contextPath + "/admin/users.jsp?error=Invalid+user+ID.");
            }
            return;
        }

        if ("activateUser".equals(action)) {
            int userId = parseInt(req.getParameter("userId"), -1);
            boolean ok = false;

            if (userId != -1) {
                ok = userDAO.activateUser(userId);
                AuditLogger.log(admin.getUserId(), "ACTIVATE_USER",
                        "Activated user ID: " + userId,
                        req.getRemoteAddr());
            }

            res.sendRedirect(contextPath + "/admin/users.jsp?" +
                    (ok ? "success=User+activated." : "error=Activate+failed."));
            return;
        }

        if ("validatePatient".equals(action)) {
            int userId = parseInt(req.getParameter("userId"), -1);

            if (userId != -1) {
                Patient patient = patientDAO.getPatientByUserId(userId);
                if (patient != null) {
                    req.setAttribute("patientToValidate", patient);
                    req.getRequestDispatcher("/admin/validatePatient.jsp").forward(req, res);
                    return;
                } else {
                    res.sendRedirect(contextPath + "/admin/users.jsp?error=Patient+not+found.");
                    return;
                }
            }
            res.sendRedirect(contextPath + "/admin/users.jsp?error=Invalid+patient+ID.");
            return;
        }

        if ("updateMedicalAid".equals(action)) {
            int userId = parseInt(req.getParameter("userId"), -1);
            String provider = req.getParameter("provider");
            String memberNumber = req.getParameter("memberNumber");

            boolean ok = false;
            if (userId != -1 && provider != null && memberNumber != null) {
                Patient patient = patientDAO.getPatientByUserId(userId);
                if (patient != null) {
                    ok = patientDAO.updateMedicalAid(patient.getPatientId(), provider, memberNumber);
                    if (ok) {
                        patientDAO.recalculatePRI(patient.getPatientId());
                        
                        List<Appointment> pendingApps = appointmentDAO.getPendingValidations();
                        
                        List<Appointment> patientPendingApps = pendingApps.stream()
                                .filter(apt -> apt.getPatientId() == patient.getPatientId())
                                .collect(Collectors.toList());
                        
                        if (!patientPendingApps.isEmpty()) {
                            List<Integer> patientIds = patientPendingApps.stream()
                                    .map(Appointment::getPatientId)
                                    .distinct()
                                    .collect(Collectors.toList());
                            
                            Map<Integer, Boolean> validationMap = medicalAidDAO.batchValidateMedicalAid(patientIds);
                            
                            for (Appointment apt : patientPendingApps) {
                                boolean isValid = validationMap.getOrDefault(apt.getPatientId(), false);
                                String newStatus = isValid ? "approved" : "rejected";
                                appointmentDAO.updateValidationStatus(apt.getAppointmentId(), newStatus);
                            }
                        }
                    }
                }
            }

            AuditLogger.log(admin.getUserId(), "UPDATE_MEDICAL_AID",
                    "Updated medical aid for user ID: " + userId + " Provider: " + provider,
                    req.getRemoteAddr());

            res.sendRedirect(contextPath + "/admin/users.jsp?" +
                    (ok ? "success=Patient+medical+aid+updated." : "error=Update+failed."));
            return;
        }

        // ==================== AUDIT LOGS ====================

        if ("viewLogs".equals(action)) {
            int limit = parseInt(req.getParameter("limit"), 100);
            List<AuditLog> logs = auditLogDAO.getRecentLogs(limit);
            req.setAttribute("auditLogs", logs);
            req.getRequestDispatcher("/admin/auditLogs.jsp").forward(req, res);
            return;
        }

        // ==================== EXPORT CSV ====================

        if ("exportAppointments".equals(action)) {
            exportAppointmentsToCSV(req, res, admin);
            return;
        }

        if ("exportUsers".equals(action)) {
            exportUsersToCSV(req, res, admin);
            return;
        }

        // ==================== DASHBOARD (DEFAULT) ====================

        try {
            int totalUsers = userDAO.getTotalUsers();
            int totalPatients = userDAO.countByRole("patient");
            int totalDoctors = userDAO.countByRole("doctor");
            int totalMedicalAid = userDAO.countByRole("medicalaid");

            int totalAppointments = appointmentDAO.countTotal();
            int pendingAppointments = appointmentDAO.countByStatus("pending");
            int confirmedAppointments = appointmentDAO.countByStatus("confirmed");
            int completedAppointments = appointmentDAO.countByStatus("completed");
            int cancelledAppointments = appointmentDAO.countByStatus("cancelled");
            int noShowAppointments = appointmentDAO.countByStatus("no-show");
            int rescheduledAppointments = appointmentDAO.countByStatus("rescheduled");

            String today = new java.text.SimpleDateFormat("yyyy-MM-dd").format(new java.util.Date());
            int todayAppointments = appointmentDAO.countByDate(today);

            int totalValidations = appointmentDAO.countTotal();
            int approvedValidations = appointmentDAO.countByStatus("completed") +
                    appointmentDAO.countByStatus("confirmed");
            int validationRate = totalValidations > 0 ? (approvedValidations * 100 / totalValidations) : 0;

            List<Patient> highRiskPatients = patientDAO.getHighRiskPatients();

            List<Appointment> recentAppointments = appointmentDAO.getAllAppointments();
            if (recentAppointments != null && recentAppointments.size() > 10) {
                recentAppointments = recentAppointments.subList(0, 10);
            }

            req.setAttribute("totalUsers", totalUsers);
            req.setAttribute("totalPatients", totalPatients);
            req.setAttribute("totalDoctors", totalDoctors);
            req.setAttribute("totalMedicalAid", totalMedicalAid);
            req.setAttribute("totalAppointments", totalAppointments);
            req.setAttribute("pendingAppointments", pendingAppointments);
            req.setAttribute("confirmedAppointments", confirmedAppointments);
            req.setAttribute("completedAppointments", completedAppointments);
            req.setAttribute("cancelledAppointments", cancelledAppointments);
            req.setAttribute("noShowAppointments", noShowAppointments);
            req.setAttribute("rescheduledAppointments", rescheduledAppointments);
            req.setAttribute("todayAppointments", todayAppointments);
            req.setAttribute("validationRate", validationRate);
            req.setAttribute("highRiskPatients", highRiskPatients);
            req.setAttribute("recentAppointments", recentAppointments);

            req.getRequestDispatcher("/admin/dashboard.jsp").forward(req, res);

        } catch (Exception e) {
            e.printStackTrace();
            res.sendRedirect(contextPath + "/admin/dashboard.jsp?error=Error+loading+dashboard.");
        }
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse res)
            throws ServletException, IOException {

        User admin = requireAdmin(req, res);
        if (admin == null) return;

        String action = req.getParameter("action");
        String contextPath = req.getContextPath();

        if ("updateUser".equals(action)) {
            int userId = parseInt(req.getParameter("userId"), -1);

            if (userId != -1) {
                User user = userDAO.getUserById(userId);
                if (user != null) {
                    String fullName = req.getParameter("fullName");
                    String email = req.getParameter("email");
                    String phone = req.getParameter("phone");

                    user.setFullName(fullName);
                    user.setEmail(email);
                    user.setPhone(phone);

                    boolean ok = userDAO.updateUser(user);

                    AuditLogger.log(admin.getUserId(), "UPDATE_USER",
                            "Updated user ID: " + userId + " - " + user.getFullName(),
                            req.getRemoteAddr());

                    if (ok) {
                        res.sendRedirect(contextPath + "/admin/users.jsp?success=User+updated+successfully.");
                    } else {
                        res.sendRedirect(contextPath + "/admin/users.jsp?error=Update+failed.");
                    }
                } else {
                    res.sendRedirect(contextPath + "/admin/users.jsp?error=User+not+found.");
                }
            } else {
                res.sendRedirect(contextPath + "/admin/users.jsp?error=Invalid+user+ID.");
            }
            return;
        }

        res.sendRedirect(contextPath + "/admin/dashboard.jsp");
    }

    // ==================== PRIVATE HELPER METHODS ====================

    private User requireAdmin(HttpServletRequest req, HttpServletResponse res)
            throws IOException {
        HttpSession session = req.getSession(false);
        if (session == null) {
            res.sendRedirect(req.getContextPath() + "/login.jsp");
            return null;
        }

        User user = (User) session.getAttribute("user");
        if (user == null || !"admin".equals(user.getRole())) {
            res.sendRedirect(req.getContextPath() + "/login.jsp");
            return null;
        }
        return user;
    }

    private boolean deleteUserCompletely(int userId) {
        try {
            User user = userDAO.getUserById(userId);
            if (user == null) return false;
            
            if ("patient".equals(user.getRole())) {
                Patient patient = patientDAO.getPatientByUserId(userId);
                if (patient != null) {
                    int patientId = patient.getPatientId();
                    appointmentDAO.deleteAppointmentsByPatient(patientId);
                    patientDAO.deletePatient(patientId);
                }
            } else if ("doctor".equals(user.getRole())) {
                Doctor doctor = doctorDAO.getDoctorByUserId(userId);
                if (doctor != null) {
                    int doctorId = doctor.getDoctorId();
                    appointmentDAO.deleteAppointmentsByDoctor(doctorId);
                    doctorDAO.deleteDoctorSchedule(doctorId);
                    doctorDAO.deleteDoctor(doctorId);
                }
            }
            
            // Delete audit logs for this user
            auditLogDAO.deleteLogsByUser(userId);
            
            return userDAO.deleteUserPermanently(userId);
            
        } catch (Exception e) {
            e.printStackTrace();
            return false;
        }
    }

    private void exportAppointmentsToCSV(HttpServletRequest req, HttpServletResponse res, User admin)
            throws IOException {

        res.setContentType("text/csv");
        res.setHeader("Content-Disposition", "attachment; filename=\"appointments_" +
                new java.text.SimpleDateFormat("yyyyMMdd_HHmmss").format(new java.util.Date()) + ".csv\"");

        List<Appointment> appointments = appointmentDAO.getAllAppointments();

        StringBuilder csv = new StringBuilder();
        csv.append("Appointment ID,Patient Name,Doctor Name,Date,Time,Status,Validation Status,Notes\n");

        for (Appointment apt : appointments) {
            csv.append(apt.getAppointmentId()).append(",");
            csv.append("\"").append(escapeCsv(apt.getPatientName())).append("\",");
            csv.append("\"").append(escapeCsv(apt.getDoctorName())).append("\",");
            csv.append(apt.getAppointmentDate()).append(",");
            csv.append(apt.getAppointmentTime()).append(",");
            csv.append(apt.getStatus()).append(",");
            csv.append(apt.getValidationStatus()).append(",");
            csv.append("\"").append(escapeCsv(apt.getNotes())).append("\"\n");
        }

        AuditLogger.log(admin.getUserId(), "EXPORT_APPOINTMENTS",
                "Exported " + appointments.size() + " appointments",
                req.getRemoteAddr());

        res.getWriter().write(csv.toString());
    }

    private void exportUsersToCSV(HttpServletRequest req, HttpServletResponse res, User admin)
            throws IOException {

        res.setContentType("text/csv");
        res.setHeader("Content-Disposition", "attachment; filename=\"users_" +
                new java.text.SimpleDateFormat("yyyyMMdd_HHmmss").format(new java.util.Date()) + ".csv\"");

        List<User> users = userDAO.getAllUsers();

        StringBuilder csv = new StringBuilder();
        csv.append("User ID,Username,Full Name,Email,Phone,Role,Status,Created Date\n");

        for (User u : users) {
            csv.append(u.getUserId()).append(",");
            csv.append("\"").append(escapeCsv(u.getUsername())).append("\",");
            csv.append("\"").append(escapeCsv(u.getFullName())).append("\",");
            csv.append("\"").append(escapeCsv(u.getEmail())).append("\",");
            csv.append("\"").append(escapeCsv(u.getPhone())).append("\",");
            csv.append(u.getRole()).append(",");
            csv.append(u.isActive() ? "Active" : "Inactive").append(",");
            csv.append(u.getCreatedAt()).append("\n");
        }

        AuditLogger.log(admin.getUserId(), "EXPORT_USERS",
                "Exported " + users.size() + " users",
                req.getRemoteAddr());

        res.getWriter().write(csv.toString());
    }

    private String escapeCsv(String value) {
        if (value == null) return "";
        return value.replace("\"", "\"\"");
    }

    private int parseInt(String s, int defaultValue) {
        try {
            return Integer.parseInt(s);
        } catch (Exception e) {
            return defaultValue;
        }
    }
}