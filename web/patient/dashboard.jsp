<%@page import="dao.PatientDAO"%>
<%@page import="dao.AppointmentDAO"%>
<%@page import="model.Patient"%>
<%@page import="model.User"%>
<%@page import="java.util.List"%>
<%@page import="model.Appointment"%>
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

    int upcoming = 0;
    int completed = 0;
    int cancelled = 0;
    int noShows = 0;
    
    for (Appointment a : appointments) {
        String status = a.getStatus();
        if ("pending".equals(status) || "confirmed".equals(status)) upcoming++;
        if ("completed".equals(status)) completed++;
        if ("cancelled".equals(status)) cancelled++;
        if ("no-show".equals(status)) noShows++;
    }

    int reliabilityScore = (patient != null) ? patient.getReliabilityScore() : 100;
    int totalAppts = (patient != null) ? patient.getTotalAppointments() : appointments.size();
    
    // ✅ CORRECT: Use actual membership_status from database
    String aidStatus = "pending";
    if (patient != null) {
        String status = patient.getMembershipStatus();
        if (status != null && !status.isEmpty()) {
            aidStatus = status;
        }
    }
    
    // Check if they have provider/number filled
    boolean hasMedicalAidInfo = (patient != null && patient.getMedicalAidProvider() != null 
            && !patient.getMedicalAidProvider().trim().isEmpty()
            && patient.getMedicalAidNumber() != null 
            && !patient.getMedicalAidNumber().trim().isEmpty());

    String firstName = user.getFullName().split(" ")[0];
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Dashboard | IHVS</title>
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
            --info: #3b82f6;
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
        
        .stats-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
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
        
        .quick-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
            gap: 20px;
            margin-bottom: 32px;
        }
        
        .quick-card {
            background: var(--bg-card);
            padding: 24px;
            border-radius: var(--radius);
            text-decoration: none;
            color: var(--text-main);
            transition: transform 0.2s, box-shadow 0.2s;
            display: block;
            text-align: center;
        }
        
        .quick-card:hover {
            transform: translateY(-4px);
            box-shadow: 0 10px 25px -5px rgba(0,0,0,0.1);
        }
        
        .quick-card.disabled {
            opacity: 0.5;
            cursor: not-allowed;
            pointer-events: none;
        }
        
        .qc-icon { font-size: 40px; color: var(--primary); margin-bottom: 16px; }
        .quick-card h4 { margin-bottom: 8px; }
        .quick-card p { font-size: 14px; color: var(--text-muted); }
        
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
        }
        
        .badge-pending { background: #fef3c7; color: #92400e; }
        .badge-confirmed { background: #dbeafe; color: #1e40af; }
        .badge-completed { background: #dcfce7; color: #166534; }
        .badge-cancelled { background: #fee2e2; color: #991b1b; }
        .badge-no-show { background: #fef3c7; color: #92400e; }
        .badge-approved { background: #dcfce7; color: #166534; }
        .badge-rejected { background: #fee2e2; color: #991b1b; }
        .badge-active { background: #dcfce7; color: #166534; }
        
        .alert {
            padding: 12px 16px;
            border-radius: var(--radius-sm);
            margin-bottom: 20px;
            display: flex;
            align-items: center;
            gap: 10px;
        }
        
        .alert-success { background: #d1fae5; color: #065f46; border-left: 4px solid var(--success); }
        .alert-warning { background: #fef3c7; color: #92400e; border-left: 4px solid var(--warning); }
        .alert-error { background: #fee2e2; color: #991b1b; border-left: 4px solid var(--danger); }
        .alert-info { background: #dbeafe; color: #1e40af; border-left: 4px solid var(--info); }
        
        .btn-outline {
            padding: 6px 12px;
            border-radius: var(--radius-sm);
            text-decoration: none;
            font-size: 13px;
            background: white;
            color: var(--text-muted);
            border: 1px solid var(--border);
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
            .stats-grid { grid-template-columns: 1fr; }
            .quick-grid { grid-template-columns: 1fr; }
            .nav-links { display: none; }
        }
    </style>
</head>
<body>

<nav class="top-nav">
    <div class="nav-container">
        <div class="logo-area">
            <i class="fas fa-heartbeat logo-icon"></i>
            <span class="brand-name">IHVS</span>
            <span class="brand-tagline">Intelligent Health Validation System</span>
        </div>
        <div class="nav-links">
            <a href="dashboard.jsp" class="nav-item active"><i class="fas fa-tachometer-alt"></i> Dashboard</a>
            <a href="bookAppointment.jsp" class="nav-item <%= !"active".equals(aidStatus) ? "disabled" : "" %>"><i class="fas fa-calendar-plus"></i> Book</a>
            <a href="myAppointments.jsp" class="nav-item"><i class="fas fa-list-ul"></i> Appointments</a>
            <a href="profile.jsp" class="nav-item"><i class="fas fa-user-circle"></i> Profile</a>
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
        <h1>Good day, <%= firstName %> 👋</h1>
        <p>Here's your health overview and recent activity</p>
    </div>

    <% if (request.getParameter("success") != null) { %>
        <div class="alert alert-success"><i class="fas fa-check-circle"></i> <%= request.getParameter("success").replace("+", " ") %></div>
    <% } %>
    <% if (request.getParameter("error") != null) { %>
        <div class="alert alert-error"><i class="fas fa-times-circle"></i> <%= request.getParameter("error").replace("+", " ") %></div>
    <% } %>

    <div class="stats-grid">
        <div class="stat-card">
            <div class="stat-icon"><i class="fas fa-star"></i></div>
            <div class="stat-info">
                <div class="value"><%= reliabilityScore %>%</div>
                <div class="label">Reliability Score</div>
            </div>
        </div>
        <div class="stat-card">
            <div class="stat-icon"><i class="fas fa-calendar-alt"></i></div>
            <div class="stat-info">
                <div class="value"><%= totalAppts %></div>
                <div class="label">Total Appointments</div>
            </div>
        </div>
        <div class="stat-card">
            <div class="stat-icon"><i class="fas fa-hourglass-half"></i></div>
            <div class="stat-info">
                <div class="value"><%= upcoming %></div>
                <div class="label">Upcoming</div>
            </div>
        </div>
        <div class="stat-card">
            <div class="stat-icon"><i class="fas fa-shield-alt"></i></div>
            <div class="stat-info">
                <div class="value" style="font-size: 18px; text-transform: capitalize;">
                    <span class="badge badge-<%= aidStatus %>"><%= aidStatus.toUpperCase() %></span>
                </div>
                <div class="label">Medical Aid</div>
            </div>
        </div>
    </div>

    <!-- ✅ CORRECTED: Medical Aid Status Warning Messages -->
    <% if (!"active".equals(aidStatus)) { %>
        <div class="alert alert-warning">
            <i class="fas fa-exclamation-triangle"></i> 
            <div>
                <strong>Medical Aid Status: <%= aidStatus.toUpperCase() %></strong><br>
                <% if ("pending".equals(aidStatus) && hasMedicalAidInfo) { %>
                    Your medical aid details have been submitted and are pending approval from the medical aid provider. 
                    You cannot book appointments until approved.
                <% } else if ("pending".equals(aidStatus) && !hasMedicalAidInfo) { %>
                    Please complete your medical aid information to enable booking appointments.
                <% } else if ("rejected".equals(aidStatus)) { %>
                    Your medical aid was rejected. Please verify your membership details and update them for re-validation.
                <% } else if ("expired".equals(aidStatus)) { %>
                    Your medical aid coverage has expired. Please update your details with current information.
                <% } %>
                <a href="profile.jsp" style="color: #92400e; font-weight: 600; display: inline-block; margin-top: 5px;">
                    <i class="fas fa-edit"></i> Update your details here
                </a>
            </div>
        </div>
    <% } %>

    <div class="quick-grid">
        <% if ("active".equals(aidStatus)) { %>
            <a href="bookAppointment.jsp" class="quick-card">
                <i class="fas fa-calendar-plus qc-icon"></i>
                <h4>Book Appointment</h4>
                <p>Schedule a visit with a specialist</p>
            </a>
        <% } else { %>
            <div class="quick-card disabled" style="opacity:0.5; cursor:not-allowed;">
                <i class="fas fa-calendar-plus qc-icon"></i>
                <h4>Book Appointment</h4>
                <p style="color: var(--danger);">⚠️ Medical aid approval required</p>
            </div>
        <% } %>
        <a href="myAppointments.jsp" class="quick-card">
            <i class="fas fa-list-ul qc-icon"></i>
            <h4>My Appointments</h4>
            <p>View and manage your visits</p>
        </a>
        <a href="profile.jsp" class="quick-card">
            <i class="fas fa-user-edit qc-icon"></i>
            <h4>Update Profile</h4>
            <p>Manage personal and medical aid info</p>
        </a>
    </div>

    <% if (!appointments.isEmpty()) { %>
        <div class="card">
            <div class="card-header">
                <h3><i class="fas fa-history"></i> Recent Appointments</h3>
                <a href="myAppointments.jsp" class="btn-outline">View All</a>
            </div>
            <div class="table-wrapper">
                <table>
                    <thead>
                        <tr><th>Doctor</th><th>Date</th><th>Time</th><th>Status</th><th>Validation</th></tr>
                    </thead>
                    <tbody>
                        <% int shown = 0; for (Appointment apt : appointments) { if (shown++ >= 5) break; %>
                        <tr>
                            <td><strong><%= apt.getDoctorName() != null ? apt.getDoctorName() : "N/A" %></strong></td>
                            <td><%= apt.getAppointmentDate() != null ? apt.getAppointmentDate() : "N/A" %></td>
                            <td><%= apt.getAppointmentTime() != null ? apt.getAppointmentTime() : "N/A" %></td>
                            <td><span class="badge badge-<%= apt.getStatus() != null ? apt.getStatus() : "pending" %>"><%= apt.getStatus() != null ? apt.getStatus().toUpperCase() : "PENDING" %></span></td>
                            <td>
                                <span class="badge badge-<%= apt.getValidationStatus() != null ? apt.getValidationStatus() : "pending" %>">
                                    <%= apt.getValidationStatus() != null ? apt.getValidationStatus().toUpperCase() : "PENDING" %>
                                </span>
                                <% if ("pending".equals(apt.getValidationStatus())) { %>
                                    <small style="display:block; font-size:10px; margin-top:4px;">(Awaiting medical aid validation)</small>
                                <% } %>
                             </tr>
                        <% } %>
                    </tbody>
                </table>
            </div>
        </div>
    <% } %>
</main>

<footer class="page-footer">
    &copy; 2026 Intelligent Health Validation System.
</footer>
</body>
</html>