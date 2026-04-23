<%@ page contentType="text/html;charset=UTF-8" %>
<%@ page import="model.User, model.Appointment, model.ValidationLog, model.MedicalAidProvider,
                 dao.AppointmentDAO, dao.MedicalAidDAO, dao.PatientDAO, java.util.List" %>
<%
  User user = (User) session.getAttribute("user");
  if (user == null || !"medicalaid".equals(user.getRole())) { 
    response.sendRedirect(request.getContextPath()+"/login.jsp"); 
    return; 
  }
  
  AppointmentDAO apptDAO = new AppointmentDAO();
  MedicalAidDAO medDAO = new MedicalAidDAO();
  PatientDAO patientDAO = new PatientDAO();
  
  List<Appointment> pending = apptDAO.getPendingValidations();
  MedicalAidProvider provider = medDAO.getProviderByUserId(user.getUserId());
  
  int approved = 0, rejected = 0;
  if (provider != null) {
    List<ValidationLog> logs = medDAO.getValidationsByProvider(provider.getProviderId());
    for (ValidationLog log : logs) {
      if ("approved".equals(log.getValidationResult())) approved++;
      if ("rejected".equals(log.getValidationResult())) rejected++;
    }
  }
  
  String firstName = user.getFullName().split(" ")[0];
  String providerName = (provider != null && provider.getProviderName() != null) ? provider.getProviderName() : "Medical Aid Provider";
%>
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Medical Aid Dashboard | IHVS Clinical Trust</title>
  <link rel="preconnect" href="https://fonts.googleapis.com"><link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
  <link href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700;800&display=swap" rel="stylesheet">
  <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0-beta3/css/all.min.css">
  <link rel="stylesheet" href="${pageContext.request.contextPath}/css/style.css">
</head>
<body>

<nav class="top-nav">
  <div class="nav-container">
    <div class="logo-area"><i class="fas fa-heartbeat logo-icon"></i><span class="brand-name">IHVS</span><span class="brand-tagline">Intelligent Health Validation</span></div>
    <div class="nav-links"><a href="dashboard.jsp" class="nav-item active"><i class="fas fa-tachometer-alt"></i> Dashboard</a><a href="validations.jsp" class="nav-item"><i class="fas fa-check-circle"></i> Validations</a><a href="history.jsp" class="nav-item"><i class="fas fa-history"></i> History</a></div>
    <div class="user-menu"><div class="user-avatar"><%= firstName.charAt(0) %></div><div class="user-info"><div class="name"><%= user.getFullName() %></div><div class="role">Medical Aid</div></div><a href="${pageContext.request.contextPath}/LogoutServlet" class="nav-item"><i class="fas fa-sign-out-alt"></i></a></div>
  </div>
</nav>

<main class="main-content">
  <div class="page-header"><h1>Welcome, <%= firstName %>!</h1><p><%= providerName %></p></div>

  <% if (request.getParameter("success") != null) { %><div class="alert alert-success"><i class="fas fa-check-circle"></i> <%= request.getParameter("success").replace("+", " ") %></div><% } %>
  <% if (request.getParameter("error") != null) { %><div class="alert alert-error"><i class="fas fa-times-circle"></i> <%= request.getParameter("error").replace("+", " ") %></div><% } %>

  <div class="stats-grid">
    <div class="stat-card"><div class="stat-icon"><i class="fas fa-clock"></i></div><div class="stat-info"><div class="value"><%= pending.size() %></div><div class="label">Pending Validations</div></div></div>
    <div class="stat-card"><div class="stat-icon"><i class="fas fa-check-circle"></i></div><div class="stat-info"><div class="value"><%= approved %></div><div class="label">Approved</div></div></div>
    <div class="stat-card"><div class="stat-icon"><i class="fas fa-times-circle"></i></div><div class="stat-info"><div class="value"><%= rejected %></div><div class="label">Rejected</div></div></div>
    <div class="stat-card"><div class="stat-icon"><i class="fas fa-chart-line"></i></div><div class="stat-info"><div class="value"><%= approved + rejected %></div><div class="label">Total Processed</div></div></div>
  </div>

  <div class="card"><div class="card-header"><span><i class="fas fa-list"></i> Pending Medical Aid Validations</span><% if (!pending.isEmpty()) { %><a href="validations.jsp" class="btn btn-primary btn-sm">View All</a><% } %></div>
    <% if (pending.isEmpty()) { %>
      <div style="padding:60px; text-align:center;"><i class="fas fa-check-circle" style="font-size:64px; color:var(--success); opacity:0.5;"></i><p style="margin-top:16px;">No pending validations. All appointments have been processed.</p></div>
    <% } else { %>
      <div class="table-wrapper"><table><thead><tr><th>Appt #</th><th>Date & Time</th><th>Patient</th><th>Medical Aid</th><th>Member #</th><th>Doctor</th><th>Actions</th></tr></thead>
      <tbody><% int displayCount = 0; for (Appointment a : pending) { if (displayCount++ >= 10) break; String memberNumber = ""; try { model.Patient p = patientDAO.getPatientById(a.getPatientId()); if (p != null && p.getMedicalAidNumber() != null) { memberNumber = p.getMedicalAidNumber(); } } catch (Exception e) { memberNumber = "N/A"; } %>
      <tr><td><strong>#<%= a.getAppointmentId() %></strong></td><td><%= a.getAppointmentDate() %> at <%= a.getAppointmentTime() %></td><td><strong><%= a.getPatientName() != null ? a.getPatientName() : "Unknown" %></strong></td><td><%= a.getMedicalAidProvider() != null ? a.getMedicalAidProvider() : "Not set" %></td><td><code><%= memberNumber %></code></td><td><%= a.getDoctorName() != null ? a.getDoctorName() : "Unknown" %></td>
      <td class="btn-group"><a href="${pageContext.request.contextPath}/MedicalAidServlet?action=approve&appointmentId=<%= a.getAppointmentId() %>&patientId=<%= a.getPatientId() %>" class="btn btn-success btn-sm" onclick="return confirm('Approve this claim?')"><i class="fas fa-check"></i> Approve</a>
      <a href="${pageContext.request.contextPath}/MedicalAidServlet?action=reject&appointmentId=<%= a.getAppointmentId() %>&patientId=<%= a.getPatientId() %>" class="btn btn-danger btn-sm" onclick="return confirm('Reject this claim?')"><i class="fas fa-times"></i> Reject</a></td></tr>
      <% } %></tbody></table></div>
      <% if (pending.size() > 10) { %><div style="padding:12px; text-align:center;"><a href="validations.jsp" class="btn btn-outline btn-sm">Show all <%= pending.size() %> pending validations →</a></div><% } %>
    <% } %>
  </div>

  <div style="display:grid; grid-template-columns:1fr 1fr; gap:24px; margin-top:24px;">
    <div class="info-box"><h4><i class="fas fa-info-circle"></i> How Validation Works</h4><ul><li>Appointments appear when patients book with medical aid</li><li>Click Approve to confirm the medical aid is valid</li><li>Click Reject if membership is invalid or expired</li><li>Your decision affects appointment confirmation</li></ul></div>
    <div class="info-box"><h4><i class="fas fa-chart-simple"></i> Today's Summary</h4><div class="info-row"><span>Pending Validations:</span><strong><%= pending.size() %></strong></div><div class="info-row"><span>Approval Rate:</span><strong><% int total = approved + rejected; int rate = total > 0 ? (approved * 100 / total) : 0; %><%= rate %>%</strong></div><div class="info-row"><span>Provider:</span><strong><%= providerName %></strong></div></div>
  </div>
</main>

<footer class="page-footer">&copy; 2025 Intelligent Health Validation System. Clinical Trust Edition.</footer>
</body>
</html>