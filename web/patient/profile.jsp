<%@page import="dao.PatientDAO"%>
<%@page import="model.Patient"%>
<%@page import="model.User"%>
<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%
    User user = (User) session.getAttribute("user");
    if (user == null || !"patient".equals(user.getRole())) {
        response.sendRedirect(request.getContextPath() + "/login.jsp");
        return;
    }

    PatientDAO patientDAO = new PatientDAO();
    Patient patient = patientDAO.getPatientByUserId(user.getUserId());

    String provider = (patient != null && patient.getMedicalAidProvider() != null) ? patient.getMedicalAidProvider() : "";
    String aidNumber = (patient != null && patient.getMedicalAidNumber() != null) ? patient.getMedicalAidNumber() : "";
    
    // Read actual membership_status from database
    String aidStatus = "pending";
    if (patient != null) {
        String status = patient.getMembershipStatus();
        if (status != null && !status.isEmpty()) {
            aidStatus = status;
        }
    }
    
    // Check if they have provider/number filled (for display purposes)
    boolean hasMedicalAidInfo = (provider != null && !provider.trim().isEmpty() 
            && aidNumber != null && !aidNumber.trim().isEmpty());
    
    int reliability = (patient != null) ? patient.getReliabilityScore() : 100;
    int noShows = (patient != null) ? patient.getNoShowCount() : 0;
    int totalAppts = (patient != null) ? patient.getTotalAppointments() : 0;
    int completed = (patient != null) ? patient.getCompletedCount() : 0;
    int cancelled = (patient != null) ? patient.getCancellationCount() : 0;
    
    double noShowRate = totalAppts > 0 ? (noShows * 100.0 / totalAppts) : 0;
    double completionRate = totalAppts > 0 ? (completed * 100.0 / totalAppts) : 0;
    double cancellationRate = totalAppts > 0 ? (cancelled * 100.0 / totalAppts) : 0;
    
    // Null-safe first name extraction
    String fullName = user.getFullName() != null ? user.getFullName() : "Patient";
    String firstName = fullName.isEmpty() ? "Patient" : fullName.split(" ")[0];
    
    // Status display variables
    String membershipStatus = aidStatus;
    String statusColor = "";
    String statusIcon = "";
    String statusMessage = "";
    
    switch (membershipStatus.toLowerCase()) {
        case "active":
            statusColor = "#166534";
            statusIcon = "✅";
            statusMessage = "Your medical aid is ACTIVE. You can book appointments.";
            break;
        case "pending":
            statusColor = "#92400e";
            statusIcon = "⏳";
            statusMessage = "Your medical aid is PENDING approval. Please wait for medical aid provider to verify your details.";
            break;
        case "rejected":
            statusColor = "#991b1b";
            statusIcon = "❌";
            statusMessage = "Your medical aid was REJECTED. Please update your details or contact support.";
            break;
        case "expired":
            statusColor = "#92400e";
            statusIcon = "⚠️";
            statusMessage = "Your medical aid has EXPIRED. Please update your details.";
            break;
        default:
            statusColor = "#64748b";
            statusIcon = "❓";
            statusMessage = "Medical aid status unknown. Please update your details.";
    }
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>My Profile | IHVS</title>
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
        
        .profile-grid { display: grid; grid-template-columns: 1fr 1fr; gap: 24px; }
        
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
        .form-hint { font-size: 12px; color: var(--text-muted); margin-top: 4px; display: block; }
        
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
        }
        .btn-primary {
            background: var(--primary);
            color: white;
        }
        .btn-primary:hover { background: var(--primary-dark); }
        
        .stats-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(150px, 1fr));
            gap: 16px;
            margin-bottom: 24px;
        }
        
        .stat-card {
            background: var(--bg-card);
            padding: 16px;
            border-radius: var(--radius);
            display: flex;
            align-items: center;
            gap: 12px;
            box-shadow: 0 1px 3px rgba(0,0,0,0.1);
        }
        
        .stat-icon {
            width: 40px;
            height: 40px;
            background: rgba(37,99,235,0.1);
            border-radius: 50%;
            display: flex;
            align-items: center;
            justify-content: center;
            font-size: 20px;
            color: var(--primary);
        }
        
        .stat-info .value { font-size: 22px; font-weight: 700; }
        .stat-info .label { font-size: 12px; color: var(--text-muted); }
        
        .badge {
            padding: 4px 12px;
            border-radius: 12px;
            font-size: 12px;
            font-weight: 600;
            display: inline-block;
        }
        
        .badge-active { background: #dcfce7; color: #166534; }
        .badge-pending { background: #fef3c7; color: #92400e; }
        .badge-rejected { background: #fee2e2; color: #991b1b; }
        .badge-expired { background: #f1f5f9; color: #475569; }
        
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
        .alert-warning { background: #fef3c7; color: #92400e; border-left: 4px solid var(--warning); }
        .alert-info { background: #dbeafe; color: #1e40af; border-left: 4px solid var(--info); }
        
        .status-banner { 
            padding: 20px; 
            border-radius: 12px; 
            margin-bottom: 20px;
            display: flex;
            align-items: center;
            gap: 15px;
            background: var(--bg-card);
            border: 1px solid var(--border);
        }
        
        .status-icon { font-size: 48px; }
        .status-content { flex: 1; }
        .status-title { font-size: 20px; font-weight: bold; margin-bottom: 5px; }
        .status-message { color: #555; }
        
        .mt-4 { margin-top: 16px; }
        
        .page-footer {
            text-align: center;
            padding: 24px;
            color: var(--text-muted);
            font-size: 13px;
            border-top: 1px solid var(--border);
            margin-top: 48px;
        }
        
        @media (max-width: 768px) {
            .profile-grid { grid-template-columns: 1fr; }
            .stats-grid { grid-template-columns: 1fr; }
            .nav-links { display: none; }
        }
        
        select.form-control { cursor: pointer; }
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
            <a href="${pageContext.request.contextPath}/patient/myAppointments.jsp" class="nav-item"><i class="fas fa-list-ul"></i> Appointments</a>
            <a href="${pageContext.request.contextPath}/patient/profile.jsp" class="nav-item active"><i class="fas fa-user-circle"></i> Profile</a>
        </div>
        <div class="user-menu">
            <div class="user-avatar"><%= firstName.charAt(0) %></div>
            <div class="user-info">
                <div class="name"><%= user.getFullName() != null ? user.getFullName() : "Patient" %></div>
                <div class="role">Patient</div>
            </div>
            <a href="${pageContext.request.contextPath}/LogoutServlet" class="nav-item"><i class="fas fa-sign-out-alt"></i></a>
        </div>
    </div>
</nav>

<main class="main-content">
    <div class="page-header">
        <h1>My Profile</h1>
        <p>Manage your personal information and medical aid details</p>
    </div>

    <% if (request.getParameter("success") != null) { %>
        <div class="alert alert-success"><i class="fas fa-check-circle"></i> <%= request.getParameter("success").replace("+", " ") %></div>
    <% } %>
    <% if (request.getParameter("error") != null) { %>
        <div class="alert alert-error"><i class="fas fa-times-circle"></i> <%= request.getParameter("error").replace("+", " ") %></div>
    <% } %>
    
    <!-- MEDICAL AID STATUS BANNER - PROMINENT DISPLAY -->
    <div class="status-banner">
        <div class="status-icon"><%= statusIcon %></div>
        <div class="status-content">
            <div class="status-title" style="color: <%= statusColor %>;">
                Medical Aid Status: <%= membershipStatus.toUpperCase() %>
            </div>
            <div class="status-message"><%= statusMessage %></div>
        </div>
    </div>
    
    <% if (!"active".equalsIgnoreCase(membershipStatus)) { %>
        <div class="alert alert-warning">
            <i class="fas fa-exclamation-triangle"></i>
            <strong>Important:</strong> You cannot book appointments until your medical aid status is <strong>ACTIVE</strong>. 
            Please update your medical aid details below and wait for approval from your medical aid provider.
        </div>
    <% } %>
    
    <div class="profile-grid">
        <!-- Personal Information Card -->
        <div class="card">
            <div class="card-header">
                <h3><i class="fas fa-user"></i> Personal Information</h3>
            </div>
            <div class="card-body">
                <form action="${pageContext.request.contextPath}/PatientServlet" method="post">
                    <input type="hidden" name="action" value="updateProfile">
                    <div class="form-group">
                        <label class="form-label">Username</label>
                        <input class="form-control" type="text" value="<%= user.getUsername() %>" disabled>
                        <small class="form-hint">Username cannot be changed.</small>
                    </div>
                    <div class="form-group">
                        <label class="form-label" for="fullName">Full Name</label>
                        <input class="form-control" type="text" id="fullName" name="fullName" value="<%= user.getFullName() != null ? user.getFullName() : "" %>" required>
                    </div>
                    <div class="form-group">
                        <label class="form-label" for="email">Email Address</label>
                        <input class="form-control" type="email" id="email" name="email" value="<%= user.getEmail() != null ? user.getEmail() : "" %>" required>
                    </div>
                    <div class="form-group">
                        <label class="form-label" for="phone">Phone Number</label>
                        <input class="form-control" type="tel" id="phone" name="phone" value="<%= user.getPhone() != null ? user.getPhone() : "" %>" required>
                    </div>
                    <button type="submit" class="btn btn-primary">Save Personal Info</button>
                </form>
            </div>
        </div>

        <!-- Medical Aid Information Card -->
        <div class="card" id="medicalAidSection">
            <div class="card-header">
                <h3><i class="fas fa-shield-alt"></i> Medical Aid Information</h3>
            </div>
            <div class="card-body">
                <form action="${pageContext.request.contextPath}/PatientServlet" method="post">
                    <input type="hidden" name="action" value="updateMedicalAid">
                    <div class="form-group">
                        <label class="form-label" for="medicalAidProvider">Medical Aid Provider</label>
                        <select class="form-control" id="medicalAidProvider" name="medicalAidProvider" required>
                            <option value="">— Select Provider —</option>
                            <option value="Discovery Health" <%= "Discovery Health".equals(provider) ? "selected" : "" %>>Discovery Health</option>
                            <option value="Momentum Health" <%= "Momentum Health".equals(provider) ? "selected" : "" %>>Momentum Health</option>
                            <option value="Bonitas" <%= "Bonitas".equals(provider) ? "selected" : "" %>>Bonitas</option>
                            <option value="Medihelp" <%= "Medihelp".equals(provider) ? "selected" : "" %>>Medihelp</option>
                            <option value="Gems" <%= "Gems".equals(provider) ? "selected" : "" %>>Gems</option>
                            <option value="Fedhealth" <%= "Fedhealth".equals(provider) ? "selected" : "" %>>Fedhealth</option>
                            <option value="Bestmed" <%= "Bestmed".equals(provider) ? "selected" : "" %>>Bestmed</option>
                            <option value="CompCare" <%= "CompCare".equals(provider) ? "selected" : "" %>>CompCare</option>
                        </select>
                    </div>
                    <div class="form-group">
                        <label class="form-label" for="medicalAidNumber">Membership Number</label>
                        <input class="form-control" type="text" id="medicalAidNumber" name="medicalAidNumber" value="<%= aidNumber %>" placeholder="Enter your membership number" required>
                    </div>
                    <div class="form-group">
                        <label class="form-label">Current Status</label>
                        <div>
                            <span class="badge badge-<%= aidStatus %>">
                                <%= aidStatus.toUpperCase() %>
                            </span>
                            <% if ("pending".equals(aidStatus)) { %>
                                <small class="form-hint" style="display: block; margin-top: 8px;">
                                    <i class="fas fa-clock"></i> 
                                    <% if (hasMedicalAidInfo) { %>
                                        Your medical aid details are pending approval from the provider. 
                                        You will be notified once approved. <strong>You cannot book appointments until approved.</strong>
                                    <% } else { %>
                                        Please complete your medical aid details above. After submission, they will be validated by the medical aid provider.
                                    <% } %>
                                </small>
                            <% } else if ("rejected".equals(aidStatus)) { %>
                                <small class="form-hint" style="display: block; margin-top: 8px; color: var(--danger);">
                                    <i class="fas fa-exclamation-triangle"></i> 
                                    Your medical aid was rejected. Please verify your membership number and provider, then update the information above for re-validation.
                                </small>
                            <% } else if ("active".equals(aidStatus)) { %>
                                <small class="form-hint" style="display: block; margin-top: 8px; color: var(--success);">
                                    <i class="fas fa-check-circle"></i> 
                                    Your medical aid is active and validated. You can book appointments.
                                </small>
                            <% } else if ("expired".equals(aidStatus)) { %>
                                <small class="form-hint" style="display: block; margin-top: 8px; color: var(--warning);">
                                    <i class="fas fa-calendar-times"></i> 
                                    Your medical aid coverage has expired. Please update your details.
                                </small>
                            <% } %>
                        </div>
                    </div>
                    <button type="submit" class="btn btn-primary">Update Medical Aid</button>
                </form>
                
                <% if (patient != null && patient.getLastValidation() != null) { %>
                    <p style="margin-top: 15px; font-size: 12px; color: #888;">
                        Last updated: <%= patient.getLastValidation() %>
                    </p>
                <% } %>
            </div>
        </div>

        <!-- Account Statistics Card (Full Width) -->
        <div class="card" style="grid-column: 1 / -1;">
            <div class="card-header">
                <h3><i class="fas fa-chart-line"></i> Account Statistics</h3>
            </div>
            <div class="card-body">
                <div class="stats-grid">
                    <div class="stat-card">
                        <div class="stat-icon"><i class="fas fa-star"></i></div>
                        <div class="stat-info">
                            <div class="value"><%= reliability %>%</div>
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
                        <div class="stat-icon"><i class="fas fa-check-circle"></i></div>
                        <div class="stat-info">
                            <div class="value"><%= completed %></div>
                            <div class="label">Completed</div>
                        </div>
                    </div>
                    <div class="stat-card">
                        <div class="stat-icon"><i class="fas fa-times-circle"></i></div>
                        <div class="stat-info">
                            <div class="value"><%= noShows %></div>
                            <div class="label">No-Shows</div>
                        </div>
                    </div>
                    <div class="stat-card">
                        <div class="stat-icon"><i class="fas fa-ban"></i></div>
                        <div class="stat-info">
                            <div class="value"><%= cancelled %></div>
                            <div class="label">Cancelled</div>
                        </div>
                    </div>
                </div>
                
                <div style="margin-top:24px; display:grid; grid-template-columns:repeat(3,1fr); gap:16px;">
                    <div style="text-align:center; padding:12px; background:var(--bg-hover); border-radius:var(--radius-sm);">
                        <div style="font-size:20px; font-weight:700; color:var(--success);"><%= String.format("%.1f", completionRate) %>%</div>
                        <div style="font-size:12px;">Completion Rate</div>
                    </div>
                    <div style="text-align:center; padding:12px; background:var(--bg-hover); border-radius:var(--radius-sm);">
                        <div style="font-size:20px; font-weight:700; color:var(--danger);"><%= String.format("%.1f", noShowRate) %>%</div>
                        <div style="font-size:12px;">No-Show Rate</div>
                    </div>
                    <div style="text-align:center; padding:12px; background:var(--bg-hover); border-radius:var(--radius-sm);">
                        <div style="font-size:20px; font-weight:700; color:var(--warning);"><%= String.format("%.1f", cancellationRate) %>%</div>
                        <div style="font-size:12px;">Cancellation Rate</div>
                    </div>
                </div>
                
                <% if (reliability < 70) { %>
                    <div class="alert alert-warning mt-4">
                        <i class="fas fa-exclamation-triangle"></i> 
                        Your reliability score is below 70%. Repeated no-shows may result in booking restrictions.
                    </div>
                <% } %>
                
                <% if (reliability >= 90 && totalAppts > 5) { %>
                    <div class="alert alert-success mt-4">
                        <i class="fas fa-trophy"></i> 
                        Excellent reliability! You have priority booking privileges.
                    </div>
                <% } %>
            </div>
        </div>
    </div>
    
    <div style="text-align: center; margin-top: 20px;">
        <a href="dashboard.jsp" style="color: var(--primary);">← Back to Dashboard</a>
    </div>
</main>

<footer class="page-footer">
    &copy; 2026 Intelligent Health Validation System. Clinical Trust Edition. All rights reserved.
</footer>
</body>
</html>