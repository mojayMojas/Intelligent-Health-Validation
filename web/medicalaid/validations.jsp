<%@ page contentType="text/html;charset=UTF-8" %>
<%@ page import="model.User, model.Appointment, model.MedicalAidProvider,
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
  
  String firstName = user.getFullName().split(" ")[0];
%>
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <title>Pending Validations | IHVS Clinical Trust</title>
  <link rel="preconnect" href="https://fonts.googleapis.com"><link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
  <link href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700;800&display=swap" rel="stylesheet">
  <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0-beta3/css/all.min.css">
  <link rel="stylesheet" href="${pageContext.request.contextPath}/css/style.css">
</head>
<body>

<nav class="top-nav">
  <div class="nav-container">
    <div class="logo-area"><i class="fas fa-heartbeat logo-icon"></i><span class="brand-name">IHVS</span><span class="brand-tagline">Intelligent Health Validation</span></div>
    <div class="nav-links"><a href="dashboard.jsp" class="nav-item"><i class="fas fa-tachometer-alt"></i> Dashboard</a><a href="validations.jsp" class="nav-item active"><i class="fas fa-check-circle"></i> Validations</a><a href="history.jsp" class="nav-item"><i class="fas fa-history"></i> History</a></div>
    <div class="user-menu"><div class="user-avatar"><%= firstName.charAt(0) %></div><div class="user-info"><div class="name"><%= user.getFullName() %></div><div class="role">Medical Aid</div></div><a href="${pageContext.request.contextPath}/LogoutServlet" class="nav-item"><i class="fas fa-sign-out-alt"></i></a></div>
  </div>
</nav>

<main class="main-content">
  <div class="page-header"><h1>Pending Validations</h1><p><%= provider != null ? provider.getProviderName() : "Medical Aid Provider" %></p></div>

  <% if (request.getParameter("success") != null) { %><div class="alert alert-success"><i class="fas fa-check-circle"></i> <%= request.getParameter("success").replace("+", " ") %></div><% } %>
  <% if (request.getParameter("error") != null) { %><div class="alert alert-error"><i class="fas fa-times-circle"></i> <%= request.getParameter("error").replace("+", " ") %></div><% } %>

  <div class="card"><div class="card-header"><strong><i class="fas fa-list"></i> Pending Validations (<%= pending.size() %>)</strong></div>
    <% if (pending.isEmpty()) { %>
      <div style="padding:60px; text-align:center;"><i class="fas fa-check-circle" style="font-size:64px; color:var(--success); opacity:0.5;"></i><p style="margin-top:16px;">No pending validations. All appointments have been processed.</p></div>
    <% } else { %>
      <div class="table-wrapper"><table><thead><tr><th>Appt #</th><th>Date & Time</th><th>Patient</th><th>Medical Aid</th><th>Member #</th><th>Doctor</th><th>Actions</th></tr></thead>
      <tbody><% for (Appointment a : pending) { String memberNumber = ""; try { model.Patient p = patientDAO.getPatientById(a.getPatientId()); if (p != null && p.getMedicalAidNumber() != null) { memberNumber = p.getMedicalAidNumber(); } } catch (Exception e) { memberNumber = "N/A"; } %>
      <tr><td><strong>#<%= a.getAppointmentId() %></strong></td><td><%= a.getAppointmentDate() %> at <%= a.getAppointmentTime() %></td><td><strong><%= a.getPatientName() != null ? a.getPatientName() : "Unknown" %></strong></td><td><%= a.getMedicalAidProvider() != null ? a.getMedicalAidProvider() : "Not set" %></td><td><code><%= memberNumber %></code></td><td><%= a.getDoctorName() != null ? a.getDoctorName() : "Unknown" %></td>
      <td class="btn-group"><a href="${pageContext.request.contextPath}/MedicalAidServlet?action=approve&appointmentId=<%= a.getAppointmentId() %>&patientId=<%= a.getPatientId() %>" class="btn btn-success btn-sm" onclick="return confirm('Approve this claim?')"><i class="fas fa-check"></i> Approve</a>
      <a href="${pageContext.request.contextPath}/MedicalAidServlet?action=reject&appointmentId=<%= a.getAppointmentId() %>&patientId=<%= a.getPatientId() %>" class="btn btn-danger btn-sm" onclick="return confirm('Reject this claim?')"><i class="fas fa-times"></i> Reject</a></td></tr>
      <% } %></tbody></table></div>
    <% } %>
  </div>

  <div class="info-box" style="margin-top:24px;"><h4><i class="fas fa-gavel"></i> Validation Guidelines</h4><ul><li><strong>Approve</strong> - Member is active and coverage is valid</li><li><strong>Reject</strong> - Member is inactive, expired, or not found</li><li>Your decision will notify the patient and doctor</li><li>Rejected appointments require patient to update medical aid details</li></ul></div>
</main>

<footer class="page-footer">&copy; 2025 Intelligent Health Validation System. Clinical Trust Edition.</footer>
</body>
</html>