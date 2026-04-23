<%@ page contentType="text/html;charset=UTF-8" %>
<%@ page import="model.User, model.Appointment, dao.AppointmentDAO, java.util.List" %>
<%
  User user = (User) session.getAttribute("user");
  if (user == null || !"admin".equals(user.getRole())) { 
    response.sendRedirect(request.getContextPath()+"/login.jsp"); 
    return; 
  }
  AppointmentDAO apptDAO = new AppointmentDAO();
  List<Appointment> appointments = apptDAO.getAllAppointments();
  
  String firstName = user.getFullName().split(" ")[0];
%>
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <title>All Appointments | IHVS Clinical Trust</title>
  <link rel="preconnect" href="https://fonts.googleapis.com"><link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
  <link href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700;800&display=swap" rel="stylesheet">
  <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0-beta3/css/all.min.css">
  <link rel="stylesheet" href="${pageContext.request.contextPath}/css/style.css">
</head>
<body>

<nav class="top-nav">
  <div class="nav-container">
    <div class="logo-area"><i class="fas fa-heartbeat logo-icon"></i><span class="brand-name">IHVS</span><span class="brand-tagline">Intelligent Health Validation</span></div>
    <div class="nav-links"><a href="dashboard.jsp" class="nav-item"><i class="fas fa-tachometer-alt"></i> Dashboard</a><a href="users.jsp" class="nav-item"><i class="fas fa-users"></i> Users</a><a href="appointments.jsp" class="nav-item active"><i class="fas fa-calendar-alt"></i> Appointments</a><a href="reports.jsp" class="nav-item"><i class="fas fa-chart-line"></i> Reports</a><a href="settings.jsp" class="nav-item"><i class="fas fa-cog"></i> Settings</a></div>
    <div class="user-menu"><div class="user-avatar"><%= firstName.charAt(0) %></div><div class="user-info"><div class="name"><%= user.getFullName() %></div><div class="role">Admin</div></div><a href="${pageContext.request.contextPath}/LogoutServlet" class="nav-item"><i class="fas fa-sign-out-alt"></i></a></div>
  </div>
</nav>

<main class="main-content">
  <div class="page-header"><h1>All Appointments</h1><p>Total: <%= appointments.size() %> appointments</p></div>

  <div class="card"><div class="card-body"><input type="text" id="filterInput" placeholder="Search by patient, doctor, status..." class="form-control" style="width: 320px;" onkeyup="filterTable()"></div></div>

  <div class="card"><div class="table-wrapper"><table id="apptTable"><thead><tr><th>#</th><th>Date</th><th>Time</th><th>Patient</th><th>Doctor</th><th>Med Aid</th><th>PRI</th><th>Status</th><th>Validation</th><th>Actions</th></tr></thead>
  <tbody><% for (Appointment a : appointments) { String patientName = a.getPatientName() != null ? a.getPatientName() : "Unknown"; String doctorName = a.getDoctorName() != null ? a.getDoctorName() : "Unknown"; String medAid = a.getMedicalAidProvider() != null ? a.getMedicalAidProvider() : "-"; String status = a.getStatus() != null ? a.getStatus() : "pending"; String validationStatus = a.getValidationStatus() != null ? a.getValidationStatus() : "pending"; int pri = a.getReliabilityScore(); %>
  <tr><td>#<%= a.getAppointmentId() %></td><td><%= a.getAppointmentDate() %></td><td><%= a.getAppointmentTime() %></td><td><%= patientName %></td><td><%= doctorName %></td><td><%= medAid %></td><td><span style="font-weight:600; color:<%= pri >= 80 ? "#1e7e34" : pri >= 60 ? "#b76e2e" : "#c23b3b" %>;"><%= pri %></span></td>
  <td><span class="badge badge-<%= status %>"><%= status.toUpperCase() %></span></td><td><span class="badge badge-<%= validationStatus %>"><%= validationStatus.toUpperCase() %></span></td>
  <td class="btn-group"><% if (!"cancelled".equals(status) && !"completed".equals(status) && !"no-show".equals(status)) { %><a href="${pageContext.request.contextPath}/UpdateAppointmentServlet?id=<%= a.getAppointmentId() %>&action=cancel" class="btn btn-danger btn-sm" onclick="return confirm('Cancel this appointment?')"><i class="fas fa-times"></i> Cancel</a><% } %></td>
  </tr><% } if (appointments.isEmpty()) { %><tr><td colspan="10" class="text-center" style="padding:40px;">No appointments found.</td></tr><% } %></tbody>
  </table></div></div>
</main>

<footer class="page-footer">&copy; 2026 Intelligent Health Validation System. Clinical Trust Edition.</footer>

<script>
function filterTable() { var input = document.getElementById('filterInput').value.toLowerCase(); var rows = document.querySelectorAll('#apptTable tbody tr'); rows.forEach(function(row) { var text = row.textContent.toLowerCase(); row.style.display = text.includes(input) ? '' : 'none'; }); }
</script>
</body>
</html>