<%@page import="java.util.List"%>
<%@page import="model.Appointment"%>
<%@page import="model.User"%>
<%@page import="dao.AppointmentDAO"%>
<%@page import="dao.PatientDAO"%>
<%@page import="model.Patient"%>
<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%
    User user = (User) session.getAttribute("user");
    if (user == null || !"patient".equals(user.getRole())) {
        response.sendRedirect(request.getContextPath() + "/login.jsp");
        return;
    }

    PatientDAO patientDAO = new PatientDAO();
    Patient patient = patientDAO.getPatientByUserId(user.getUserId());
    
    AppointmentDAO aptDAO = new AppointmentDAO();
    List<Appointment> appointments = new java.util.ArrayList<>();
    
    if (patient != null) {
        appointments = aptDAO.getAppointmentsByPatient(patient.getPatientId());
    }
    
    String firstName = user.getFullName().split(" ")[0];
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>My Appointments | IHVS</title>
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700;800&display=swap" rel="stylesheet">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0-beta3/css/all.min.css">
    <style>
        :root {
            --primary: #2563eb;
            --primary-dark: #1d4ed8;
            --success: #10b981;
            --danger: #ef4444;
            --warning: #f59e0b;
            --text-main: #1a1f36;
            --text-muted: #64748b;
            --border: #e2e8f0;
            --bg: #f5f7fb;
            --bg-card: #ffffff;
            --radius: 12px;
            --radius-sm: 8px;
        }
        
        * { margin: 0; padding: 0; box-sizing: border-box; }
        
        body {
            font-family: 'Inter', sans-serif;
            background: var(--bg);
            color: var(--text-main);
            line-height: 1.5;
        }
        
        .top-nav {
            background: var(--bg-card);
            border-bottom: 1px solid var(--border);
            padding: 0 24px;
            position: sticky;
            top: 0;
            z-index: 100;
        }
        
        .nav-container {
            max-width: 1400px;
            margin: 0 auto;
            display: flex;
            justify-content: space-between;
            align-items: center;
            height: 70px;
        }
        
        .logo-area { display: flex; align-items: center; gap: 12px; }
        .logo-icon { font-size: 28px; color: var(--primary); }
        .brand-name { font-size: 22px; font-weight: 700; color: #1e293b; }
        .brand-tagline { font-size: 12px; color: var(--text-muted); margin-left: 8px; }
        
        .nav-links { display: flex; gap: 8px; }
        .nav-item {
            padding: 8px 16px;
            text-decoration: none;
            color: var(--text-muted);
            border-radius: var(--radius-sm);
            transition: all 0.2s;
            display: flex;
            align-items: center;
            gap: 8px;
        }
        .nav-item:hover { background: #f1f5f9; color: var(--primary); }
        .nav-item.active { background: var(--primary); color: white; }
        
        .user-menu { display: flex; align-items: center; gap: 16px; }
        .user-avatar {
            width: 40px; height: 40px;
            background: var(--primary); color: white;
            border-radius: 50%; display: flex;
            align-items: center; justify-content: center;
            font-weight: 600; font-size: 18px;
        }
        .user-info .name { font-weight: 600; font-size: 14px; }
        .user-info .role { font-size: 12px; color: var(--text-muted); }
        
        .main-content { max-width: 1400px; margin: 0 auto; padding: 32px 24px; }
        .page-header { margin-bottom: 32px; }
        .page-header h1 { font-size: 28px; font-weight: 700; margin-bottom: 8px; }
        .page-header p { color: var(--text-muted); }
        
        .card {
            background: var(--bg-card);
            border-radius: var(--radius);
            box-shadow: 0 1px 3px rgba(0,0,0,0.1);
            overflow: hidden;
        }
        
        .card-header {
            padding: 20px 24px;
            border-bottom: 1px solid var(--border);
            display: flex;
            justify-content: space-between;
            align-items: center;
        }
        
        .card-header h3 { font-size: 18px; font-weight: 600; display: flex; align-items: center; gap: 8px; }
        
        .table-wrapper { overflow-x: auto; }
        table { width: 100%; border-collapse: collapse; }
        th, td { padding: 12px 16px; text-align: left; border-bottom: 1px solid var(--border); }
        th { background: #f8fafc; font-weight: 600; font-size: 14px; }
        
        .badge {
            padding: 4px 8px;
            border-radius: 12px;
            font-size: 12px;
            font-weight: 600;
            display: inline-block;
        }
        
        .badge-pending { background: #fef3c7; color: #92400e; }
        .badge-confirmed { background: #dbeafe; color: #1e40af; }
        .badge-completed { background: #dcfce7; color: #166534; }
        .badge-cancelled { background: #fee2e2; color: #991b1b; }
        .badge-no-show { background: #fef3c7; color: #92400e; }
        .badge-approved { background: #dcfce7; color: #166534; }
        .badge-rejected { background: #fee2e2; color: #991b1b; }
        
        .btn-group { display: flex; gap: 8px; }
        .btn-danger {
            padding: 6px 12px;
            border-radius: var(--radius-sm);
            text-decoration: none;
            font-size: 12px;
            background: var(--danger);
            color: white;
            border: none;
            cursor: pointer;
            display: inline-flex;
            align-items: center;
            gap: 6px;
        }
        .btn-danger:hover { background: #dc2626; }
        
        .alert {
            padding: 12px 16px;
            border-radius: var(--radius-sm);
            margin-bottom: 20px;
            display: flex;
            align-items: center;
            gap: 10px;
        }
        
        .alert-success { background: #d1fae5; color: #065f46; border-left: 4px solid var(--success); }
        .alert-error { background: #fee2e2; color: #991b1b; border-left: 4px solid var(--danger); }
        
        .table-empty { text-align: center; padding: 60px; }
        .table-empty i { font-size: 48px; opacity: 0.5; }
        .table-empty p { margin-top: 16px; }
        
        .btn-primary-sm {
            padding: 8px 16px;
            background: var(--primary);
            color: white;
            text-decoration: none;
            border-radius: var(--radius-sm);
            display: inline-block;
            margin-top: 16px;
        }
        
        .page-footer {
            text-align: center;
            padding: 24px;
            color: var(--text-muted);
            font-size: 13px;
            border-top: 1px solid var(--border);
            margin-top: 48px;
        }
        
        @media (max-width: 768px) {
            .nav-links { display: none; }
            th, td { padding: 8px 12px; font-size: 13px; }
        }
        
        .validation-pending-small {
            display: block;
            font-size: 10px;
            margin-top: 4px;
            color: var(--warning);
        }
    </style>
</head>
<body>

<nav class="top-nav">
    <div class="nav-container">
        <div class="logo-area">
            <i class="fas fa-heartbeat logo-icon"></i>
            <span class="brand-name">IHVS</span>
            <span class="brand-tagline">Intelligent Health Validation</span>
        </div>
        <div class="nav-links">
            <a href="${pageContext.request.contextPath}/patient/dashboard.jsp" class="nav-item"><i class="fas fa-tachometer-alt"></i> Dashboard</a>
            <a href="${pageContext.request.contextPath}/patient/bookAppointment.jsp" class="nav-item"><i class="fas fa-calendar-plus"></i> Book</a>
            <a href="${pageContext.request.contextPath}/patient/myAppointments.jsp" class="nav-item active"><i class="fas fa-list-ul"></i> Appointments</a>
            <a href="${pageContext.request.contextPath}/patient/profile.jsp" class="nav-item"><i class="fas fa-user-circle"></i> Profile</a>
        </div>
        <div class="user-menu">
            <div class="user-avatar"><%= firstName.charAt(0) %></div>
            <div class="user-info">
                <div class="name"><%= user.getFullName() %></div>
                <div class="role">Patient</div>
            </div>
            <a href="${pageContext.request.contextPath}/LogoutServlet" class="nav-item"><i class="fas fa-sign-out-alt"></i></a>
        </div>
    </div>
</nav>

<main class="main-content">
    <div class="page-header">
        <h1>My Appointments</h1>
        <p>View and manage your scheduled appointments</p>
    </div>

    <% if (request.getParameter("success") != null) { %>
        <div class="alert alert-success"><i class="fas fa-check-circle"></i> <%= request.getParameter("success").replace("+", " ") %></div>
    <% } %>
    <% if (request.getParameter("error") != null) { %>
        <div class="alert alert-error"><i class="fas fa-times-circle"></i> <%= request.getParameter("error").replace("+", " ") %></div>
    <% } %>

    <div class="card">
        <div class="card-header">
            <h3><i class="fas fa-calendar-alt"></i> All Appointments</h3>
            <span class="badge badge-confirmed"><%= appointments.size() %> Total</span>
        </div>
        <div class="table-wrapper">
            <table id="appointmentsTable">
                <thead>
                    <tr>
                        <th>Doctor</th>
                        <th>Date</th>
                        <th>Time</th>
                        <th>Status</th>
                        <th>Validation</th>
                        <th>Actions</th>
                    </tr>
                </thead>
                <tbody>
                    <% if (appointments.isEmpty()) { %>
                        <tr class="table-empty">
                            <td colspan="6">
                                <i class="fas fa-calendar-times"></i>
                                <p>No appointments found.</p>
                                <a href="${pageContext.request.contextPath}/patient/bookAppointment.jsp" class="btn-primary-sm">Book an Appointment</a>
                            </td>
                        </tr>
                    <% } else { 
                        for (Appointment apt : appointments) { 
                            String status = apt.getStatus() != null ? apt.getStatus() : "pending";
                            String validationStatus = apt.getValidationStatus() != null ? apt.getValidationStatus() : "pending";
                    %>
                        <tr>
                            <td><strong><%= apt.getDoctorName() != null ? apt.getDoctorName() : "N/A" %></strong></td>
                            <td><%= apt.getAppointmentDate() != null ? apt.getAppointmentDate() : "N/A" %></td>
                            <td><%= apt.getAppointmentTime() != null ? apt.getAppointmentTime() : "N/A" %></td>
                            <td><span class="badge badge-<%= status %>"><%= status.toUpperCase() %></span></td>
                            <td>
                                <span class="badge badge-<%= validationStatus %>"><%= validationStatus.toUpperCase() %></span>
                                <% if ("pending".equals(validationStatus)) { %>
                                    <small class="validation-pending-small">
                                        <i class="fas fa-spinner fa-spin"></i> Validating in background
                                    </small>
                                <% } %>
                            </td>
                            <td class="btn-group">
                                <% if ("pending".equals(status) || "confirmed".equals(status)) { %>
                                    <a href="${pageContext.request.contextPath}/UpdateAppointmentServlet?id=<%= apt.getAppointmentId() %>&action=cancel" 
                                       class="btn-danger" 
                                       onclick="return confirm('Are you sure you want to cancel this appointment?')">
                                        <i class="fas fa-times"></i> Cancel
                                    </a>
                                <% } else { %>
                                    <span style="color:var(--text-muted); font-size:12px;">—</span>
                                <% } %>
                            </td>
                        </tr>
                    <% } 
                    } %>
                </tbody>
            </table>
        </div>
    </div>
</main>

<footer class="page-footer">
    &copy; 2026 Intelligent Health Validation System. All rights reserved.
</footer>

<script>
    // Auto-refresh validation status every 10 seconds for pending validations
    setTimeout(function() {
        location.reload();
    }, 10000);
</script>
</body>
</html>