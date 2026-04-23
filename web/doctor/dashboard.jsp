<%@page import="java.util.List"%>
<%@page import="model.Appointment"%>
<%@page import="model.User"%>
<%@page import="dao.AppointmentDAO"%>
<%@page import="dao.DoctorDAO"%>
<%@page import="model.Doctor"%>
<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%
    User user = (User) session.getAttribute("user");
    if (user == null || !"doctor".equals(user.getRole())) {
        response.sendRedirect(request.getContextPath() + "/login.jsp");
        return;
    }

    DoctorDAO doctorDAO = new DoctorDAO();
    AppointmentDAO aptDAO = new AppointmentDAO();
    
    Doctor doctor = doctorDAO.getDoctorByUserId(user.getUserId());
    List<Appointment> appointments = new java.util.ArrayList<>();
    
    if (doctor != null) {
        appointments = aptDAO.getAppointmentsByDoctor(doctor.getDoctorId());
    }
    
    // Calculate statistics
    int pending = 0, confirmed = 0, completed = 0, cancelled = 0, noShows = 0;
    for (Appointment a : appointments) {
        String status = a.getStatus();
        if ("pending".equals(status)) pending++;
        else if ("confirmed".equals(status)) confirmed++;
        else if ("completed".equals(status)) completed++;
        else if ("cancelled".equals(status)) cancelled++;
        else if ("no-show".equals(status)) noShows++;
    }
    
    String firstName = user.getFullName().split(" ")[0];
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Doctor Dashboard | IHVS</title>
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
            --bg-hover: #f1f5f9;
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
        .nav-item:hover { background: var(--bg-hover); color: var(--primary); }
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
        
        .stats-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(180px, 1fr));
            gap: 20px;
            margin-bottom: 32px;
        }
        
        .stat-card {
            background: var(--bg-card);
            padding: 20px;
            border-radius: var(--radius);
            display: flex;
            align-items: center;
            gap: 16px;
            box-shadow: 0 1px 3px rgba(0,0,0,0.1);
        }
        
        .stat-icon {
            width: 48px;
            height: 48px;
            background: rgba(37,99,235,0.1);
            border-radius: 50%;
            display: flex;
            align-items: center;
            justify-content: center;
            font-size: 24px;
            color: var(--primary);
        }
        
        .stat-info .value { font-size: 28px; font-weight: 700; }
        .stat-info .label { font-size: 14px; color: var(--text-muted); }
        
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
        
        .btn-group { display: flex; gap: 8px; flex-wrap: wrap; }
        .btn {
            padding: 6px 12px;
            border-radius: var(--radius-sm);
            text-decoration: none;
            font-size: 12px;
            border: none;
            cursor: pointer;
            display: inline-flex;
            align-items: center;
            gap: 6px;
            transition: all 0.2s;
        }
        .btn-success { background: var(--success); color: white; }
        .btn-success:hover { background: #059669; }
        .btn-danger { background: var(--danger); color: white; }
        .btn-danger:hover { background: #dc2626; }
        .btn-primary { background: var(--primary); color: white; }
        .btn-primary:hover { background: var(--primary-dark); }
        .btn-warning { background: var(--warning); color: white; }
        .btn-warning:hover { background: #d97706; }
        .btn-outline {
            background: white;
            color: var(--text-muted);
            border: 1px solid var(--border);
        }
        .btn-outline.active {
            background: var(--primary);
            color: white;
            border-color: var(--primary);
        }
        
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
        
        .filter-buttons { display: flex; gap: 10px; margin-bottom: 20px; flex-wrap: wrap; }
        
        .page-footer {
            text-align: center;
            padding: 24px;
            color: var(--text-muted);
            font-size: 13px;
            border-top: 1px solid var(--border);
            margin-top: 48px;
        }
        
        @media (max-width: 768px) {
            .stats-grid { grid-template-columns: 1fr; }
            .nav-links { display: none; }
            th, td { padding: 8px 12px; font-size: 13px; }
        }
        
        .validation-badge-small {
            font-size: 10px;
            display: block;
            margin-top: 4px;
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
            <a href="dashboard.jsp" class="nav-item active"><i class="fas fa-tachometer-alt"></i> Dashboard</a>
            <a href="manageAppointments.jsp" class="nav-item"><i class="fas fa-list-ul"></i> Appointments</a>
            <a href="schedule.jsp" class="nav-item"><i class="fas fa-clock"></i> Availability</a>
            <a href="profile.jsp" class="nav-item"><i class="fas fa-user-md"></i> Profile</a>
        </div>
        <div class="user-menu">
            <div class="user-avatar"><%= firstName.charAt(0) %></div>
            <div class="user-info">
                <div class="name">Dr. <%= user.getFullName() %></div>
                <div class="role">Doctor</div>
            </div>
            <a href="${pageContext.request.contextPath}/LogoutServlet" class="nav-item"><i class="fas fa-sign-out-alt"></i></a>
        </div>
    </div>
</nav>

<main class="main-content">
    <div class="page-header">
        <h1>Welcome, Dr. <%= firstName %> 👨‍⚕️</h1>
        <p>Here's your practice overview and today's schedule</p>
    </div>

    <% if (request.getParameter("success") != null) { %>
        <div class="alert alert-success"><i class="fas fa-check-circle"></i> <%= request.getParameter("success").replace("+", " ") %></div>
    <% } %>

    <div class="stats-grid">
        <div class="stat-card">
            <div class="stat-icon"><i class="fas fa-hourglass-half"></i></div>
            <div class="stat-info">
                <div class="value"><%= pending %></div>
                <div class="label">Pending</div>
            </div>
        </div>
        <div class="stat-card">
            <div class="stat-icon"><i class="fas fa-check-circle"></i></div>
            <div class="stat-info">
                <div class="value"><%= confirmed %></div>
                <div class="label">Confirmed</div>
            </div>
        </div>
        <div class="stat-card">
            <div class="stat-icon"><i class="fas fa-check-double"></i></div>
            <div class="stat-info">
                <div class="value"><%= completed %></div>
                <div class="label">Completed</div>
            </div>
        </div>
        <div class="stat-card">
            <div class="stat-icon"><i class="fas fa-user-slash"></i></div>
            <div class="stat-info">
                <div class="value"><%= noShows %></div>
                <div class="label">No-Shows</div>
            </div>
        </div>
    </div>

    <div class="card">
        <div class="card-header">
            <h3><i class="fas fa-calendar-alt"></i> Recent Appointments</h3>
            <a href="manageAppointments.jsp" class="btn btn-outline">View All</a>
        </div>
        <div class="table-wrapper">
            <table>
                <thead>
                    <tr><th>Date</th><th>Time</th><th>Patient</th><th>Medical Aid</th><th>PRI</th><th>Status</th><th>Validation</th><th>Actions</th></tr>
                </thead>
                <tbody>
                    <% if (appointments.isEmpty()) { %>
                        <tr><td colspan="8" style="text-align:center; padding:60px;"><i class="fas fa-calendar-times" style="font-size:48px; opacity:0.5;"></i><p style="margin-top:16px;">No appointments yet.</p></td></tr>
                    <% } else { 
                        int shown = 0;
                        for (Appointment apt : appointments) { 
                            if (shown++ >= 10) break;
                            String status = apt.getStatus() != null ? apt.getStatus() : "pending";
                            String validationStatus = apt.getValidationStatus() != null ? apt.getValidationStatus() : "pending";
                            int score = apt.getReliabilityScore();
                    %>
                        <tr>
                            <td><strong><%= apt.getAppointmentDate() %></strong></td>
                            <td><%= apt.getAppointmentTime() %></td>
                            <td><strong><%= apt.getPatientName() != null ? apt.getPatientName() : "Unknown" %></strong></td>
                            <td><%= apt.getMedicalAidProvider() != null ? apt.getMedicalAidProvider() : "—" %></td>
                            <td><span style="font-weight:600; color:<%= score >= 80 ? "#10b981" : score >= 60 ? "#f59e0b" : "#ef4444" %>;"><%= score %></span></td>
                            <td><span class="badge badge-<%= status %>"><%= status.toUpperCase() %></span></td>
                            <td>
                                <span class="badge badge-<%= validationStatus %>"><%= validationStatus.toUpperCase() %></span>
                                <% if ("pending".equals(validationStatus)) { %>
                                    <small class="validation-badge-small"><i class="fas fa-spinner fa-spin"></i> Processing</small>
                                <% } %>
                            </td>
                            <td class="btn-group">
                                <% if ("pending".equals(status)) { %>
                                    <a href="${pageContext.request.contextPath}/UpdateAppointmentServlet?id=<%= apt.getAppointmentId() %>&action=confirm" class="btn btn-success" onclick="return confirm('Confirm this appointment?')"><i class="fas fa-check"></i> Confirm</a>
                                    <a href="${pageContext.request.contextPath}/UpdateAppointmentServlet?id=<%= apt.getAppointmentId() %>&action=cancel" class="btn btn-danger" onclick="return confirm('Cancel this appointment?')"><i class="fas fa-times"></i> Cancel</a>
                                <% } else if ("confirmed".equals(status)) { %>
                                    <a href="${pageContext.request.contextPath}/UpdateAppointmentServlet?id=<%= apt.getAppointmentId() %>&action=complete" class="btn btn-primary" onclick="return confirm('Mark as completed?')"><i class="fas fa-check-double"></i> Complete</a>
                                    <a href="${pageContext.request.contextPath}/UpdateAppointmentServlet?id=<%= apt.getAppointmentId() %>&action=no-show" class="btn btn-warning" onclick="return confirm('Mark as no-show? This will affect patient reliability score.')"><i class="fas fa-user-slash"></i> No-Show</a>
                                <% } %>
                            </td>
                        </tr>
                    <% } } %>
                </tbody>
            </table>
        </div>
    </div>
</main>

<footer class="page-footer">
    &copy; 2026 Intelligent Health Validation System. Clinical Trust Edition.
</footer>
</body>
</html>