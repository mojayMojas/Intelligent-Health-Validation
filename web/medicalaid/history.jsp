<%@ page contentType="text/html;charset=UTF-8" %>
<%@ page import="model.User, model.ValidationLog, model.MedicalAidProvider,
                 dao.MedicalAidDAO, java.util.List" %>
<%
  User user = (User) session.getAttribute("user");
  if (user == null || !"medicalaid".equals(user.getRole())) { 
    response.sendRedirect(request.getContextPath()+"/login.jsp"); 
    return; 
  }
  
  MedicalAidDAO medDAO = new MedicalAidDAO();
  MedicalAidProvider provider = medDAO.getProviderByUserId(user.getUserId());
  
  List<ValidationLog> history = new java.util.ArrayList<>();
  if (provider != null) {
    history = medDAO.getValidationsByProvider(provider.getProviderId());
  }
  
  int approved = 0, rejected = 0;
  for (ValidationLog v : history) {
    if ("approved".equals(v.getValidationResult())) approved++;
    if ("rejected".equals(v.getValidationResult())) rejected++;
  }
  
  String firstName = user.getFullName().split(" ")[0];
%>
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <title>Validation History | IHVS Clinical Trust</title>
  <link rel="preconnect" href="https://fonts.googleapis.com"><link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
  <link href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700;800&display=swap" rel="stylesheet">
  <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0-beta3/css/all.min.css">
  <link rel="stylesheet" href="${pageContext.request.contextPath}/css/style.css">
</head>
<body>

<nav class="top-nav">
  <div class="nav-container">
    <div class="logo-area"><i class="fas fa-heartbeat logo-icon"></i><span class="brand-name">IHVS</span><span class="brand-tagline">Intelligent Health Validation</span></div>
    <div class="nav-links"><a href="dashboard.jsp" class="nav-item"><i class="fas fa-tachometer-alt"></i> Dashboard</a><a href="validations.jsp" class="nav-item"><i class="fas fa-check-circle"></i> Validations</a><a href="history.jsp" class="nav-item active"><i class="fas fa-history"></i> History</a></div>
    <div class="user-menu"><div class="user-avatar"><%= firstName.charAt(0) %></div><div class="user-info"><div class="name"><%= user.getFullName() %></div><div class="role">Medical Aid</div></div><a href="${pageContext.request.contextPath}/LogoutServlet" class="nav-item"><i class="fas fa-sign-out-alt"></i></a></div>
  </div>
</nav>

<main class="main-content">
  <div class="page-header"><h1>Validation History</h1><p><%= provider != null ? provider.getProviderName() : "Medical Aid Provider" %></p></div>

  <div class="stats-grid">
    <div class="stat-card"><div class="stat-icon"><i class="fas fa-check-circle"></i></div><div class="stat-info"><div class="value" style="color:var(--success);"><%= approved %></div><div class="label">Approved</div></div></div>
    <div class="stat-card"><div class="stat-icon"><i class="fas fa-times-circle"></i></div><div class="stat-info"><div class="value" style="color:var(--danger);"><%= rejected %></div><div class="label">Rejected</div></div></div>
    <div class="stat-card"><div class="stat-icon"><i class="fas fa-chart-line"></i></div><div class="stat-info"><div class="value"><%= history.size() %></div><div class="label">Total</div></div></div>
  </div>

  <div class="card"><div class="card-header"><strong><i class="fas fa-list"></i> All Validations (<%= history.size() %>)</strong></div>
    <% if (history.isEmpty()) { %>
      <div style="padding:60px; text-align:center;"><i class="fas fa-history" style="font-size:64px; opacity:0.5;"></i><p style="margin-top:16px;">No validation history yet.</p></div>
    <% } else { %>
      <div class="table-wrapper"><table><thead><tr><th>Date & Time</th><th>Patient</th><th>Member #</th><th>Provider</th><th>Result</th><th>Response</th></tr></thead>
      <tbody><% for (ValidationLog v : history) { %>
      <tr><td><%= v.getValidationTime() != null ? v.getValidationTime() : "Unknown" %></td><td><strong><%= v.getPatientName() != null ? v.getPatientName() : "Unknown" %></strong></td><td><%= v.getMemberNumber() != null ? v.getMemberNumber() : "-" %></td><td><%= v.getAidProvider() != null ? v.getAidProvider() : "-" %></td>
      <td><span class="badge <%= "approved".equals(v.getValidationResult()) ? "badge-active" : "badge-cancelled" %>"><%= v.getValidationResult() != null ? v.getValidationResult().toUpperCase() : "UNKNOWN" %></span></td>
      <td><%= v.getResponseMessage() != null ? v.getResponseMessage() : "-" %></td></tr>
      <% } %></tbody></table></div>
    <% } %>
  </div>

  <div class="card"><div class="card-header"><strong><i class="fas fa-filter"></i> Filter Options</strong></div><div class="card-body"><div style="display:flex; gap:12px;"><button onclick="filterTable('approved')" class="btn btn-outline btn-sm">Show Approved Only</button><button onclick="filterTable('rejected')" class="btn btn-outline btn-sm">Show Rejected Only</button><button onclick="filterTable('all')" class="btn btn-outline btn-sm">Show All</button></div></div></div>
</main>

<footer class="page-footer">&copy; 2025 Intelligent Health Validation System. Clinical Trust Edition.</footer>

<script>
function filterTable(status) {
  const rows = document.querySelectorAll('.data-table tbody tr, table tbody tr');
  rows.forEach(row => {
    const resultCell = row.cells[4];
    if (!resultCell) return;
    const result = resultCell.textContent.trim().toLowerCase();
    if (status === 'all') row.style.display = '';
    else if (status === 'approved' && result === 'approved') row.style.display = '';
    else if (status === 'rejected' && result === 'rejected') row.style.display = '';
    else row.style.display = 'none';
  });
}
</script>
</body>
</html>