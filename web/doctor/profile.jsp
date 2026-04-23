<%@ page contentType="text/html;charset=UTF-8" %>
<%@ page import="model.User, model.Doctor, model.DoctorSchedule, dao.DoctorDAO, java.util.List" %>
<%
  User user = (User) session.getAttribute("user");
  if (user == null || !"doctor".equals(user.getRole())) { 
    response.sendRedirect(request.getContextPath()+"/login.jsp"); 
    return; 
  }
  
  DoctorDAO doctorDAO = new DoctorDAO();
  Doctor doctor = doctorDAO.getDoctorByUserId(user.getUserId());
  List<DoctorSchedule> schedule = null;
  
  if (doctor != null) {
      schedule = doctorDAO.getDoctorSchedule(doctor.getDoctorId());
  }
  
  String firstName = user.getFullName().split(" ")[0];
%>
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <title>Doctor Profile | IHVS</title>
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
    .btn-outline {
      background: white;
      color: var(--text-muted);
      border: 1px solid var(--border);
    }
    .btn-outline:hover { background: var(--bg-hover); }
    .btn-sm { padding: 6px 12px; font-size: 12px; }
    
    .info-row {
      display: flex;
      justify-content: space-between;
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
    
    .mt-4 { margin-top: 16px; }
    .text-center { text-align: center; }
    
    @media (max-width: 768px) {
      .profile-grid { grid-template-columns: 1fr; }
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
      <span class="brand-tagline">Intelligent Health Validation</span>
    </div>
    <div class="nav-links">
      <a href="dashboard.jsp" class="nav-item"><i class="fas fa-tachometer-alt"></i> Dashboard</a>
      <a href="manageAppointments.jsp" class="nav-item"><i class="fas fa-list-ul"></i> Appointments</a>
      <a href="schedule.jsp" class="nav-item"><i class="fas fa-clock"></i> Availability</a>
      <a href="profile.jsp" class="nav-item active"><i class="fas fa-user-md"></i> Profile</a>
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
    <h1>My Profile</h1>
    <p>Manage your professional information and availability</p>
  </div>

  <% String success = request.getParameter("success"); if(success != null){ %>
    <div class="alert alert-success"><i class="fas fa-check-circle"></i> <%= success.replace("+", " ") %></div>
  <% } %>
  <% String error = request.getParameter("error"); if(error != null){ %>
    <div class="alert alert-error"><i class="fas fa-times-circle"></i> <%= error.replace("+", " ") %></div>
  <% } %>

  <div class="profile-grid">
    <div class="card">
      <div class="card-header"><h3><i class="fas fa-user-edit"></i> Personal Information</h3></div>
      <div class="card-body">
        <form method="post" action="${pageContext.request.contextPath}/DoctorServlet" id="profileForm">
          <input type="hidden" name="action" value="updateProfile">
          <div class="form-group">
            <label class="form-label">Username</label>
            <input type="text" value="<%= user.getUsername() %>" class="form-control" disabled>
          </div>
          <div class="form-group">
            <label class="form-label" for="fullName">Full Name</label>
            <input type="text" id="fullName" name="fullName" value="<%= user.getFullName() %>" required class="form-control">
          </div>
          <div class="form-group">
            <label class="form-label" for="email">Email</label>
            <input type="email" id="email" name="email" value="<%= user.getEmail() %>" required class="form-control">
          </div>
          <div class="form-group">
            <label class="form-label" for="phone">Phone</label>
            <input type="tel" id="phone" name="phone" value="<%= user.getPhone() != null ? user.getPhone() : "" %>" class="form-control">
          </div>
          <% if (doctor != null) { %>
          <div class="form-group">
            <label class="form-label" for="specialization">Specialization</label>
            <input type="text" id="specialization" name="specialization" value="<%= doctor.getSpecialization() != null ? doctor.getSpecialization() : "" %>" class="form-control" placeholder="e.g., Cardiologist">
          </div>
          <div class="form-group">
            <label class="form-label" for="qualification">Qualification</label>
            <input type="text" id="qualification" name="qualification" value="<%= doctor.getQualification() != null ? doctor.getQualification() : "" %>" class="form-control" placeholder="e.g., MBChB">
          </div>
          <div class="form-group">
            <label class="form-label" for="consultationFee">Consultation Fee (ZAR)</label>
            <input type="number" id="consultationFee" name="consultationFee" value="<%= doctor.getConsultationFee() %>" step="0.01" min="0" class="form-control">
          </div>
          <% } %>
          <button type="submit" class="btn btn-primary" id="saveProfileBtn"><i class="fas fa-save"></i> Save Changes</button>
        </form>
      </div>
    </div>

    <div>
      <div class="card">
        <div class="card-header"><h3><i class="fas fa-id-card"></i> Account Details</h3></div>
        <div class="card-body">
          <div class="info-row"><span class="key">Role</span><span class="val">Doctor</span></div>
          <div class="info-row"><span class="key">Account Status</span><span class="val"><span class="badge badge-active">Active</span></span></div>
          <div class="info-row"><span class="key">Member Since</span><span class="val"><%= user.getCreatedAt() != null ? user.getCreatedAt() : "N/A" %></span></div>
        </div>
      </div>

      <% if (doctor != null) { %>
      <div class="card" style="margin-top:24px;">
        <div class="card-header"><h3><i class="fas fa-clock"></i> Current Schedule</h3></div>
        <div class="card-body">
          <% if (schedule == null || schedule.isEmpty()) { %>
            <p class="text-center" style="color:var(--text-muted); padding:20px;">No schedule set.</p>
          <% } else { 
            for (DoctorSchedule ds : schedule) { %>
              <div class="info-row">
                <span class="key"><strong><%= ds.getDayOfWeek() %></strong></span>
                <span class="val"><%= ds.getStartTime() %> - <%= ds.getEndTime() %></span>
              </div>
          <% } } %>
          <div style="margin-top:16px;">
            <a href="schedule.jsp" class="btn btn-outline btn-sm"><i class="fas fa-edit"></i> Manage Schedule</a>
          </div>
        </div>
      </div>
      <% } %>
    </div>
  </div>
</main>

<footer class="page-footer">&copy; 2026 Intelligent Health Validation System. Clinical Trust Edition.</footer>

<script>
  // Prevent double form submission
  document.getElementById('profileForm').addEventListener('submit', function(e) {
    const submitBtn = document.getElementById('saveProfileBtn');
    if (submitBtn.disabled) {
      e.preventDefault();
      return;
    }
    submitBtn.disabled = true;
    submitBtn.innerHTML = '<i class="fas fa-spinner fa-spin"></i> Saving...';
  });
</script>
</body>
</html>