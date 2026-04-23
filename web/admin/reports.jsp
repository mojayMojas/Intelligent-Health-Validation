<%@ page contentType="text/html;charset=UTF-8" pageEncoding="UTF-8" %>
<%@page import="dao.AdminDAO"%>
<%@page import="model.User"%>
<%@page import="java.util.Calendar"%>
<%@page import="java.text.SimpleDateFormat"%>
<%
    User user = (User) session.getAttribute("user");
    if (user == null || !"admin".equals(user.getRole())) {
        response.sendRedirect(request.getContextPath() + "/login.jsp");
        return;
    }
    
    AdminDAO adminDAO = new AdminDAO();
    int currentYear = Calendar.getInstance().get(Calendar.YEAR);
    int currentMonth = Calendar.getInstance().get(Calendar.MONTH) + 1;
    int[] monthlyStats = adminDAO.getMonthlyStats(currentYear, currentMonth);
    
    String firstName = user.getFullName().split(" ")[0];
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Reports | IHVS Clinical Trust</title>
    <link rel="preconnect" href="https://fonts.googleapis.com"><link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700;800&display=swap" rel="stylesheet">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0-beta3/css/all.min.css">
    <link rel="stylesheet" href="${pageContext.request.contextPath}/css/style.css">
</head>
<body>

<nav class="top-nav">
    <div class="nav-container">
        <div class="logo-area"><i class="fas fa-heartbeat logo-icon"></i><span class="brand-name">IHVS</span><span class="brand-tagline">Intelligent Health Validation</span></div>
        <div class="nav-links">
            <a href="${pageContext.request.contextPath}/admin/dashboard.jsp" class="nav-item"><i class="fas fa-tachometer-alt"></i> Dashboard</a>
            <a href="${pageContext.request.contextPath}/admin/users.jsp" class="nav-item"><i class="fas fa-users"></i> Users</a>
            <a href="${pageContext.request.contextPath}/admin/appointments.jsp" class="nav-item"><i class="fas fa-calendar-alt"></i> Appointments</a>
            <a href="${pageContext.request.contextPath}/admin/reports.jsp" class="nav-item active"><i class="fas fa-chart-line"></i> Reports</a>
            <a href="${pageContext.request.contextPath}/admin/settings.jsp" class="nav-item"><i class="fas fa-cog"></i> Settings</a>
        </div>
        <div class="user-menu"><div class="user-avatar"><%= firstName.charAt(0) %></div><div class="user-info"><div class="name"><%= user.getFullName() %></div><div class="role">Admin</div></div><a href="${pageContext.request.contextPath}/LogoutServlet" class="nav-item"><i class="fas fa-sign-out-alt"></i></a></div>
    </div>
</nav>

<main class="main-content">
    <div class="page-header"><h1>System Reports</h1><p>System performance and appointment statistics</p></div>

    <!-- Monthly Statistics -->
    <div class="card">
        <div class="card-header"><h3><i class="fas fa-chart-bar"></i> Monthly Appointment Statistics</h3></div>
        <div class="card-body">
            <div class="stats-grid" style="grid-template-columns: repeat(6, 1fr);">
                <div class="stat-card"><div class="stat-icon"><i class="fas fa-clock"></i></div><div class="stat-info"><div class="value"><%= monthlyStats[0] %></div><div class="label">Pending</div></div></div>
                <div class="stat-card"><div class="stat-icon"><i class="fas fa-check-circle"></i></div><div class="stat-info"><div class="value"><%= monthlyStats[1] %></div><div class="label">Confirmed</div></div></div>
                <div class="stat-card"><div class="stat-icon"><i class="fas fa-times-circle"></i></div><div class="stat-info"><div class="value"><%= monthlyStats[2] %></div><div class="label">Cancelled</div></div></div>
                <div class="stat-card"><div class="stat-icon"><i class="fas fa-sync"></i></div><div class="stat-info"><div class="value"><%= monthlyStats[3] %></div><div class="label">Rescheduled</div></div></div>
                <div class="stat-card"><div class="stat-icon"><i class="fas fa-check-double"></i></div><div class="stat-info"><div class="value"><%= monthlyStats[4] %></div><div class="label">Completed</div></div></div>
                <div class="stat-card"><div class="stat-icon"><i class="fas fa-user-slash"></i></div><div class="stat-info"><div class="value"><%= monthlyStats[5] %></div><div class="label">No-Show</div></div></div>
            </div>
        </div>
    </div>

    <!-- Export Data - Using AdminServlet (CORRECT) -->
    <div class="card">
        <div class="card-header"><h3><i class="fas fa-download"></i> Export Data</h3></div>
        <div class="card-body">
            <div style="display: flex; gap: 16px; flex-wrap: wrap;">
                <a href="${pageContext.request.contextPath}/AdminServlet?action=exportAppointments" class="btn btn-primary">
                    <i class="fas fa-file-csv"></i> Export Appointments (CSV)
                </a>
                <a href="${pageContext.request.contextPath}/AdminServlet?action=exportUsers" class="btn btn-primary">
                    <i class="fas fa-users"></i> Export Users (CSV)
                </a>
            </div>
        </div>
    </div>
</main>

<footer class="page-footer">&copy; 2025 Intelligent Health Validation System. Clinical Trust Edition.</footer>
</body>
</html>