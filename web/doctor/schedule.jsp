<%@page import="dao.DoctorDAO"%>
<%@page import="model.Doctor"%>
<%@page import="model.DoctorSchedule"%>
<%@page import="model.User"%>
<%@page import="java.util.List"%>
<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%
    User user = (User) session.getAttribute("user");
    if (user == null || !"doctor".equals(user.getRole())) {
        response.sendRedirect(request.getContextPath() + "/login.jsp");
        return;
    }

    DoctorDAO doctorDAO = new DoctorDAO();
    Doctor doctor = doctorDAO.getDoctorByUserId(user.getUserId());
    List<DoctorSchedule> schedule = null;
    
    if (doctor != null) {
        schedule = doctorDAO.getDoctorSchedule(doctor.getDoctorId());
    }
    
    boolean hasSchedule = schedule != null && !schedule.isEmpty();
    String firstName = user.getFullName().split(" ")[0];
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>My Availability | IHVS</title>
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
        
        .availability-grid { display: grid; grid-template-columns: 1fr 340px; gap: 24px; align-items: start; }
        
        .card {
            background: var(--bg-card);
            border-radius: var(--radius);
            box-shadow: 0 1px 3px rgba(0,0,0,0.1);
            overflow: hidden;
        }
        
        .card-header {
            padding: 20px 24px;
            border-bottom: 1px solid var(--border);
        }
        
        .card-header h3 { font-size: 18px; font-weight: 600; display: flex; align-items: center; gap: 8px; }
        .card-body { padding: 24px; }
        
        .form-group { margin-bottom: 20px; }
        .form-label {
            display: block;
            margin-bottom: 8px;
            font-weight: 500;
            font-size: 14px;
        }
        .form-control {
            width: 100%;
            padding: 10px 12px;
            border: 1px solid var(--border);
            border-radius: var(--radius-sm);
            font-size: 14px;
            font-family: inherit;
        }
        .form-control:focus {
            outline: none;
            border-color: var(--primary);
            box-shadow: 0 0 0 3px rgba(37,99,235,0.1);
        }
        .form-row { display: grid; grid-template-columns: 1fr 1fr; gap: 16px; }
        
        .btn {
            padding: 10px 20px;
            border-radius: var(--radius-sm);
            font-size: 14px;
            font-weight: 500;
            cursor: pointer;
            border: none;
            transition: all 0.2s;
            display: inline-flex;
            align-items: center;
            gap: 8px;
            text-decoration: none;
        }
        .btn-primary {
            background: var(--primary);
            color: white;
        }
        .btn-primary:hover { background: var(--primary-dark); }
        .btn-danger {
            background: var(--danger);
            color: white;
        }
        .btn-danger:hover { background: #dc2626; }
        .btn-sm { padding: 6px 12px; font-size: 12px; }
        
        .info-row {
            display: flex;
            justify-content: space-between;
            align-items: center;
            padding: 12px 0;
            border-bottom: 1px solid var(--border);
        }
        .info-row:last-child { border-bottom: none; }
        .info-row .key { color: var(--text-muted); font-size: 14px; }
        .info-row .val { font-weight: 500; }
        
        .badge {
            padding: 4px 8px;
            border-radius: 12px;
            font-size: 12px;
            font-weight: 600;
            display: inline-block;
        }
        .badge-active { background: #dcfce7; color: #166534; }
        .badge-pending { background: #fef3c7; color: #92400e; }
        
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
        
        .page-footer {
            text-align: center;
            padding: 24px;
            color: var(--text-muted);
            font-size: 13px;
            border-top: 1px solid var(--border);
            margin-top: 48px;
        }
        
        @media (max-width: 768px) {
            .availability-grid { grid-template-columns: 1fr; }
            .form-row { grid-template-columns: 1fr; }
            .nav-links { display: none; }
        }
        
        .loading-btn {
            opacity: 0.7;
            cursor: wait;
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
            <a href="dashboard.jsp" class="nav-item"><i class="fas fa-tachometer-alt"></i> Dashboard</a>
            <a href="manageAppointments.jsp" class="nav-item"><i class="fas fa-list-ul"></i> Appointments</a>
            <a href="schedule.jsp" class="nav-item active"><i class="fas fa-clock"></i> Availability</a>
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
        <h1>My Availability</h1>
        <p>Set the days and times you are available to see patients</p>
    </div>

    <% if (request.getParameter("success") != null) { %>
        <div class="alert alert-success"><i class="fas fa-check-circle"></i> <%= request.getParameter("success").replace("+", " ") %></div>
    <% } %>
    <% if (request.getParameter("error") != null) { %>
        <div class="alert alert-error"><i class="fas fa-times-circle"></i> <%= request.getParameter("error").replace("+", " ") %></div>
    <% } %>

    <div class="availability-grid">
        <!-- Add Schedule Form -->
        <div class="card">
            <div class="card-header"><h3><i class="fas fa-plus-circle"></i> Add Schedule Entry</h3></div>
            <div class="card-body">
                <form action="${pageContext.request.contextPath}/DoctorServlet" method="post" id="addScheduleForm">
                    <input type="hidden" name="action" value="addSchedule">
                    <div class="form-group">
                        <label class="form-label">Day of Week</label>
                        <select class="form-control" name="dayOfWeek" required>
                            <option value="Monday">Monday</option>
                            <option value="Tuesday">Tuesday</option>
                            <option value="Wednesday">Wednesday</option>
                            <option value="Thursday">Thursday</option>
                            <option value="Friday">Friday</option>
                            <option value="Saturday">Saturday</option>
                            <option value="Sunday">Sunday</option>
                        </select>
                    </div>
                    <div class="form-row">
                        <div class="form-group">
                            <label class="form-label">Start Time</label>
                            <input type="time" class="form-control" name="startTime" required>
                        </div>
                        <div class="form-group">
                            <label class="form-label">End Time</label>
                            <input type="time" class="form-control" name="endTime" required>
                        </div>
                    </div>
                    <button type="submit" class="btn btn-primary" id="submitBtn"><i class="fas fa-save"></i> Add to Schedule</button>
                </form>
            </div>
        </div>

        <!-- Current Schedule Display -->
        <div class="card">
            <div class="card-header"><h3><i class="fas fa-calendar-week"></i> Current Schedule</h3></div>
            <div class="card-body">
                <% if (!hasSchedule) { %>
                    <p style="padding:20px; color:var(--text-muted); text-align:center;">No schedule set. Add your available days above.</p>
                <% } else { 
                    for (DoctorSchedule ds : schedule) { %>
                        <div class="info-row">
                            <span class="key"><strong><%= ds.getDayOfWeek() %></strong></span>
                            <span class="val">
                                <%= ds.getStartTime() %> - <%= ds.getEndTime() %>
                                <a href="${pageContext.request.contextPath}/DoctorServlet?action=removeSchedule&scheduleId=<%= ds.getScheduleId() %>" 
                                   class="btn btn-danger btn-sm" style="margin-left:10px;" 
                                   onclick="return confirm('Remove this schedule entry?')">
                                    <i class="fas fa-trash"></i>
                                </a>
                            </span>
                        </div>
                    <% } 
                } %>
            </div>
        </div>
    </div>

    <!-- Status Card -->
    <div class="card" style="margin-top:24px;">
        <div class="card-header"><h3><i class="fas fa-info-circle"></i> Availability Status</h3></div>
        <div class="card-body">
            <div style="display:flex; align-items:center; gap:20px; flex-wrap:wrap;">
                <span class="badge <%= hasSchedule ? "badge-active" : "badge-pending" %>">
                    <%= hasSchedule ? "SCHEDULE SET" : "NO SCHEDULE" %>
                </span>
                <span style="color:var(--text-muted);">
                    <%= hasSchedule ? "You have " + schedule.size() + " schedule entries. Patients can book appointments during these times." : "Please add schedule entries to start receiving appointments." %>
                </span>
            </div>
        </div>
    </div>
</main>

<footer class="page-footer">&copy; 2026 Intelligent Health Validation System.</footer>

<script>
    // Prevent double form submission
    document.getElementById('addScheduleForm').addEventListener('submit', function(e) {
        const submitBtn = document.getElementById('submitBtn');
        if (submitBtn.disabled) {
            e.preventDefault();
            return;
        }
        submitBtn.disabled = true;
        submitBtn.innerHTML = '<i class="fas fa-spinner fa-spin"></i> Adding...';
    });
</script>
</body>
</html>