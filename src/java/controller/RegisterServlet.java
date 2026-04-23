package controller;

import dao.DoctorDAO;
import dao.PatientDAO;
import dao.UserDAO;
import model.User;
import util.AuditLogger;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.*;
import java.io.IOException;

@WebServlet("/RegisterServlet")
public class RegisterServlet extends HttpServlet {

    private final UserDAO    userDAO    = new UserDAO();
    private final PatientDAO patientDAO = new PatientDAO();
    private final DoctorDAO  doctorDAO  = new DoctorDAO();

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse res)
            throws ServletException, IOException {
        req.getRequestDispatcher("/register.jsp").forward(req, res);
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse res)
            throws ServletException, IOException {

        try {
            // Get parameters
            String username = req.getParameter("username");
            String password = req.getParameter("password");
            String confirmPassword = req.getParameter("confirmPassword");
            String fullName = req.getParameter("fullName");
            String email = req.getParameter("email");
            String phone = req.getParameter("phone");
            String role = req.getParameter("role");

            // Debug logging
            System.out.println("=== Registration Attempt ===");
            System.out.println("Username: " + username);
            System.out.println("Email: " + email);
            System.out.println("Role: " + role);
            System.out.println("Full Name: " + fullName);

            // --- Validation ---
            if (isEmpty(username) || isEmpty(password) || isEmpty(fullName) ||
                    isEmpty(email) || isEmpty(phone) || isEmpty(role)) {
                req.setAttribute("error", "All fields are required.");
                req.getRequestDispatcher("/register.jsp").forward(req, res);
                return;
            }

            if (!password.equals(confirmPassword)) {
                req.setAttribute("error", "Passwords do not match.");
                req.getRequestDispatcher("/register.jsp").forward(req, res);
                return;
            }

            if (password.length() < 8) {
                req.setAttribute("error", "Password must be at least 8 characters.");
                req.getRequestDispatcher("/register.jsp").forward(req, res);
                return;
            }

            // Check if username exists
            if (userDAO.isUsernameExists(username)) {
                req.setAttribute("error", "Username already taken.");
                req.getRequestDispatcher("/register.jsp").forward(req, res);
                return;
            }

            // Check if email exists
            if (userDAO.isEmailExists(email)) {
                req.setAttribute("error", "Email already registered.");
                req.getRequestDispatcher("/register.jsp").forward(req, res);
                return;
            }

            // Validate role - allow all four roles
            if (!"patient".equals(role) && !"doctor".equals(role) && 
                !"admin".equals(role) && !"medicalaid".equals(role)) {
                req.setAttribute("error", "Invalid role selected.");
                req.getRequestDispatcher("/register.jsp").forward(req, res);
                return;
            }

            // Create user object
            User user = new User();
            user.setUsername(username.trim());
            user.setPassword(password);
            user.setFullName(fullName.trim());
            user.setEmail(email.trim().toLowerCase());
            user.setPhone(phone.trim());
            user.setRole(role);

            // Register user
            boolean registered = userDAO.registerUser(user);
            System.out.println("User registration result: " + registered);

            if (!registered) {
                req.setAttribute("error", "Registration failed. Database error.");
                req.getRequestDispatcher("/register.jsp").forward(req, res);
                return;
            }

            System.out.println("User registered with ID: " + user.getUserId());

            // Create role-specific profile (only patients and doctors need additional tables)
            if ("patient".equals(role)) {
                boolean patientCreated = patientDAO.createPatient(user.getUserId());
                System.out.println("Patient profile created: " + patientCreated);
                
                if (!patientCreated) {
                    System.out.println("Warning: Patient profile creation failed - but user was created");
                }
                
            } else if ("doctor".equals(role)) {
                String specialization = req.getParameter("specialization");
                double fee = 0;
                
                try { 
                    String feeStr = req.getParameter("consultationFee");
                    if (feeStr != null && !feeStr.trim().isEmpty()) {
                        fee = Double.parseDouble(feeStr.trim());
                    }
                } catch (NumberFormatException e) {
                    System.out.println("Invalid consultation fee format, using default: " + e.getMessage());
                    fee = 350.00; // Default fee
                }
                
                // FIXED: createDoctor only takes 3 parameters
                boolean doctorCreated = doctorDAO.createDoctor(
                    user.getUserId(),
                    isEmpty(specialization) ? "General Practitioner" : specialization.trim(),
                    fee
                );
                System.out.println("Doctor profile created: " + doctorCreated);
                
                if (!doctorCreated) {
                    System.out.println("Warning: Doctor profile creation failed - but user was created");
                }
            }
            // Admin and Medical Aid don't need additional profiles - they just use the users table

            // Log successful registration
            AuditLogger.log(user.getUserId(), "REGISTER", 
                          "New " + role + " registered: " + username, 
                          req.getRemoteAddr());

            // Redirect to login with success message
            res.sendRedirect(req.getContextPath() + "/login.jsp?success=Registration+successful!+Please+login.");

        } catch (Exception e) {
            System.out.println("Unexpected error during registration: " + e.getMessage());
            e.printStackTrace();
            req.setAttribute("error", "Registration failed: " + e.getMessage());
            req.getRequestDispatcher("/register.jsp").forward(req, res);
        }
    }

    private boolean isEmpty(String s) { 
        return s == null || s.trim().isEmpty(); 
    }
}