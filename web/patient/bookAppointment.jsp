<%@page import="java.util.List"%>
<%@page import="model.Doctor"%>
<%@page import="model.DoctorSchedule"%>
<%@page import="model.User"%>
<%@page import="dao.DoctorDAO"%>
<%@page import="dao.PatientDAO"%>
<%@page import="model.Patient"%>
<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%
    User user = (User) session.getAttribute("user");
    if (user == null || !"patient".equals(user.getRole())) {
        response.sendRedirect(request.getContextPath() + "/login.jsp");
        return;
    }

    PatientDAO patientDAO = new PatientDAO();
    Patient patient = patientDAO.getPatientByUserId(user.getUserId());
    
    String aidStatus = "pending";
    if (patient != null && patient.getMedicalAidProvider() != null 
            && patient.getMedicalAidNumber() != null 
            && !patient.getMedicalAidProvider().trim().isEmpty()
            && !patient.getMedicalAidNumber().trim().isEmpty()) {
        aidStatus = "active";
    }

    DoctorDAO doctorDAO = new DoctorDAO();
    List<Doctor> doctors = doctorDAO.getAllDoctors();
    
    // Load schedule for each doctor and store in a simple format
    java.util.Map<Integer, String> doctorScheduleMap = new java.util.HashMap<>();
    if (doctors != null) {
        for (Doctor d : doctors) {
            List<DoctorSchedule> schedule = doctorDAO.getDoctorSchedule(d.getDoctorId());
            if (schedule != null && !schedule.isEmpty()) {
                StringBuilder sb = new StringBuilder();
                for (DoctorSchedule ds : schedule) {
                    String start = ds.getStartTime();
                    String end = ds.getEndTime();
                    if (start != null && start.length() > 5) start = start.substring(0, 5);
                    if (end != null && end.length() > 5) end = end.substring(0, 5);
                    if (sb.length() > 0) sb.append("|");
                    sb.append(ds.getDayOfWeek()).append(":").append(start).append("-").append(end);
                }
                doctorScheduleMap.put(d.getDoctorId(), sb.toString());
            }
        }
    }
    
    String today = new java.text.SimpleDateFormat("yyyy-MM-dd").format(new java.util.Date());
    String firstName = "";
    if (user.getFullName() != null && !user.getFullName().trim().isEmpty()) {
        firstName = user.getFullName().split(" ")[0];
    } else {
        firstName = "Patient";
    }
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Book Appointment | IHVS</title>
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
            --radius: 12px;
            --radius-sm: 8px;
        }
        
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }
        
        body {
            font-family: 'Inter', sans-serif;
            background: var(--bg);
            color: var(--text-main);
            line-height: 1.5;
        }
        
        /* Navigation */
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
        
        .logo-area {
            display: flex;
            align-items: center;
            gap: 12px;
        }
        
        .logo-icon {
            font-size: 28px;
            color: var(--primary);
        }
        
        .brand-name {
            font-size: 22px;
            font-weight: 700;
            color: #1e293b;
        }
        
        .brand-tagline {
            font-size: 12px;
            color: var(--text-muted);
            margin-left: 8px;
        }
        
        .nav-links {
            display: flex;
            gap: 8px;
        }
        
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
        
        .nav-item:hover {
            background: #f1f5f9;
            color: var(--primary);
        }
        
        .nav-item.active {
            background: var(--primary);
            color: white;
        }
        
        .user-menu {
            display: flex;
            align-items: center;
            gap: 16px;
        }
        
        .user-avatar {
            width: 40px;
            height: 40px;
            background: var(--primary);
            color: white;
            border-radius: 50%;
            display: flex;
            align-items: center;
            justify-content: center;
            font-weight: 600;
            font-size: 18px;
        }
        
        .user-info .name {
            font-weight: 600;
            font-size: 14px;
        }
        
        .user-info .role {
            font-size: 12px;
            color: var(--text-muted);
        }
        
        /* Main Content */
        .main-content {
            max-width: 1400px;
            margin: 0 auto;
            padding: 32px 24px;
        }
        
        .page-header {
            margin-bottom: 32px;
        }
        
        .page-header h1 {
            font-size: 28px;
            font-weight: 700;
            margin-bottom: 8px;
        }
        
        .page-header p {
            color: var(--text-muted);
        }
        
        /* Cards */
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
        
        .card-header h3 {
            font-size: 18px;
            font-weight: 600;
            display: flex;
            align-items: center;
            gap: 8px;
        }
        
        .card-body {
            padding: 24px;
        }
        
        /* Forms */
        .form-group {
            margin-bottom: 20px;
        }
        
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
            transition: border-color 0.2s;
        }
        
        .form-control:focus {
            outline: none;
            border-color: var(--primary);
            box-shadow: 0 0 0 3px rgba(37,99,235,0.1);
        }
        
        .form-row {
            display: grid;
            grid-template-columns: 1fr 1fr;
            gap: 16px;
        }
        
        textarea.form-control {
            resize: vertical;
        }
        
        /* Buttons */
        .btn-group {
            display: flex;
            gap: 12px;
            margin-top: 24px;
        }
        
        .btn {
            padding: 10px 20px;
            border-radius: var(--radius-sm);
            font-size: 14px;
            font-weight: 500;
            text-decoration: none;
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
        
        .btn-primary:hover:not(:disabled) {
            background: var(--primary-dark);
        }
        
        .btn-primary:disabled {
            opacity: 0.6;
            cursor: not-allowed;
        }
        
        .btn-outline {
            background: white;
            color: var(--text-muted);
            border: 1px solid var(--border);
        }
        
        .btn-outline:hover {
            background: #f8fafc;
        }
        
        /* Alerts */
        .alert {
            padding: 12px 16px;
            border-radius: var(--radius-sm);
            margin-bottom: 20px;
            display: flex;
            align-items: center;
            gap: 10px;
        }
        
        .alert-warning {
            background: #fef3c7;
            color: #92400e;
            border-left: 4px solid var(--warning);
        }
        
        .alert-error {
            background: #fee2e2;
            color: #991b1b;
            border-left: 4px solid var(--danger);
        }
        
        .alert-success {
            background: #d1fae5;
            color: #065f46;
            border-left: 4px solid var(--success);
        }
        
        /* Grid */
        .booking-grid {
            display: grid;
            grid-template-columns: 1fr 340px;
            gap: 24px;
            align-items: start;
        }
        
        .schedule-info {
            background: #f8fafc;
            padding: 12px;
            border-radius: var(--radius-sm);
            margin-bottom: 16px;
        }
        
        .schedule-info ul {
            margin: 8px 0 0 20px;
            padding: 0;
        }
        
        .schedule-info li {
            margin: 4px 0;
        }
        
        .info-row {
            display: flex;
            justify-content: space-between;
            padding: 12px 0;
            border-bottom: 1px solid var(--border);
        }
        
        .info-row:last-child {
            border-bottom: none;
        }
        
        .info-row .key {
            color: var(--text-muted);
            font-size: 14px;
        }
        
        .info-row .val {
            font-weight: 500;
        }
        
        .badge {
            padding: 4px 8px;
            border-radius: 12px;
            font-size: 12px;
            font-weight: 600;
        }
        
        .badge-active {
            background: #dcfce7;
            color: #166534;
        }
        
        .badge-pending {
            background: #fef3c7;
            color: #92400e;
        }
        
        .info-box {
            background: #f8fafc;
            padding: 20px;
            border-radius: var(--radius);
            margin-top: 20px;
        }
        
        .info-box h4 {
            margin-bottom: 12px;
            display: flex;
            align-items: center;
            gap: 8px;
        }
        
        .info-box ul {
            margin-left: 20px;
            color: #475569;
            font-size: 13px;
        }
        
        .info-box li {
            margin: 8px 0;
        }
        
        .page-footer {
            text-align: center;
            padding: 24px;
            color: var(--text-muted);
            font-size: 13px;
            border-top: 1px solid var(--border);
            margin-top: 48px;
        }
        
        .loading-spinner {
            display: inline-block;
            width: 16px;
            height: 16px;
            border: 2px solid #f3f3f3;
            border-top: 2px solid var(--primary);
            border-radius: 50%;
            animation: spin 1s linear infinite;
        }
        
        @keyframes spin {
            0% { transform: rotate(0deg); }
            100% { transform: rotate(360deg); }
        }
        
        @media (max-width: 768px) {
            .booking-grid {
                grid-template-columns: 1fr;
            }
            .form-row {
                grid-template-columns: 1fr;
            }
            .nav-links {
                display: none;
            }
        }
        
        select:disabled {
            background-color: #f1f5f9;
            cursor: not-allowed;
        }
        
        .mt-4 { margin-top: 16px; }
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
            <a href="${pageContext.request.contextPath}/patient/bookAppointment.jsp" class="nav-item active"><i class="fas fa-calendar-plus"></i> Book</a>
            <a href="${pageContext.request.contextPath}/patient/myAppointments.jsp" class="nav-item"><i class="fas fa-list-ul"></i> Appointments</a>
            <a href="${pageContext.request.contextPath}/patient/profile.jsp" class="nav-item"><i class="fas fa-user-circle"></i> Profile</a>
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
        <h1>Schedule New Appointment</h1>
        <p>Fill in the details below to book your visit with a specialist</p>
    </div>

    <% if (!"active".equals(aidStatus)) { %>
        <div class="alert alert-warning">
            <i class="fas fa-exclamation-triangle"></i>
            Your medical aid status is <strong><%= aidStatus %></strong>. 
            <a href="${pageContext.request.contextPath}/patient/profile.jsp" style="color: #92400e;">Update your details here</a>
        </div>
    <% } %>

    <% if (request.getParameter("error") != null) { %>
        <div class="alert alert-error">
            <i class="fas fa-times-circle"></i>
            <%= request.getParameter("error").replace("+", " ") %>
        </div>
    <% } %>

    <div class="booking-grid">
        <div class="card">
            <div class="card-header">
                <h3><i class="fas fa-notes-medical"></i> Appointment Details</h3>
            </div>
            <div class="card-body">
                <form action="${pageContext.request.contextPath}/BookAppointmentServlet" method="post" id="appointmentForm">
                    <div class="form-group">
                        <label class="form-label">Select Doctor</label>
                        <select class="form-control" id="doctorId" name="doctorId" required onchange="updateScheduleInfo()">
                            <option value="">— Choose a doctor —</option>
                            <% if (doctors != null) {
                                for (Doctor d : doctors) { %>
                                <option value="<%= d.getDoctorId() %>" data-schedule="<%= doctorScheduleMap.get(d.getDoctorId()) != null ? doctorScheduleMap.get(d.getDoctorId()) : "" %>">
                                    Dr. <%= d.getFullName() != null ? d.getFullName() : "Unknown" %> — <%= d.getSpecialization() != null ? d.getSpecialization() : "General" %> (R<%= String.format("%.0f", d.getConsultationFee()) %>)
                                </option>
                            <% } } %>
                        </select>
                    </div>

                    <div id="scheduleInfo" class="schedule-info" style="display:none;">
                        <strong><i class="fas fa-clock"></i> Doctor's Schedule:</strong>
                        <div id="scheduleDetails"></div>
                    </div>

                    <div class="form-row">
                        <div class="form-group">
                            <label class="form-label">Appointment Date</label>
                            <input class="form-control" type="date" id="appointmentDate" name="appointmentDate" min="<%= today %>" required>
                        </div>
                        <div class="form-group">
                            <label class="form-label">Appointment Time</label>
                            <select class="form-control" id="appointmentTime" name="appointmentTime" required disabled>
                                <option value="">— Select doctor and date first —</option>
                            </select>
                        </div>
                    </div>

                    <div class="form-group">
                        <label class="form-label">Symptoms / Reason for Visit</label>
                        <textarea class="form-control" name="notes" rows="4" placeholder="Please describe your symptoms..." required></textarea>
                    </div>

                    <div class="btn-group">
                        <button type="submit" class="btn btn-primary" id="submitBtn"><i class="fas fa-check-circle"></i> Confirm Booking</button>
                        <a href="${pageContext.request.contextPath}/patient/dashboard.jsp" class="btn btn-outline">Cancel</a>
                    </div>
                </form>
            </div>
        </div>

        <div>
            <div class="card">
                <div class="card-header">
                    <h3><i class="fas fa-shield-alt"></i> Medical Aid</h3>
                </div>
                <div class="card-body">
                    <div class="info-row">
                        <span class="key">Provider</span>
                        <span class="val"><%= (patient != null && patient.getMedicalAidProvider() != null) ? patient.getMedicalAidProvider() : "Not set" %></span>
                    </div>
                    <div class="info-row">
                        <span class="key">Status</span>
                        <span class="val">
                            <span class="badge <%= "active".equals(aidStatus) ? "badge-active" : "badge-pending" %>">
                                <%= aidStatus.toUpperCase() %>
                            </span>
                        </span>
                    </div>
                    <div class="info-row">
                        <span class="key">Reliability Score</span>
                        <span class="val"><%= (patient != null) ? patient.getReliabilityScore() : 100 %>%</span>
                    </div>
                </div>
            </div>
            <div class="info-box">
                <h4><i class="fas fa-info-circle"></i> Important Notes</h4>
                <ul>
                    <li>Medical aid validated in background after booking</li>
                    <li>Reminders sent 24h & 1h before appointment</li>
                    <li>Cancellations must be at least 2 hours prior</li>
                    <li>Repeated no-shows reduce reliability score</li>
                </ul>
            </div>
        </div>
    </div>
</main>

<footer class="page-footer">
    &copy; 2026 Intelligent Health Validation System.
</footer>

<script>
    let doctorScheduleData = {};
    
    function updateScheduleInfo() {
        const select = document.getElementById('doctorId');
        const selectedOption = select.options[select.selectedIndex];
        const scheduleData = selectedOption.getAttribute('data-schedule');
        const scheduleDiv = document.getElementById('scheduleInfo');
        const detailsDiv = document.getElementById('scheduleDetails');
        
        doctorScheduleData = {};
        
        console.log("Raw schedule data:", scheduleData);
        
        if (scheduleData && scheduleData.length > 0) {
            const entries = scheduleData.split('|');
            let html = '<ul style="margin:0; padding-left:20px;">';
            
            for (let i = 0; i < entries.length; i++) {
                const entry = entries[i];
                console.log("Processing entry:", entry);
                
                const firstColonIndex = entry.indexOf(':');
                if (firstColonIndex === -1) continue;
                
                const day = entry.substring(0, firstColonIndex);
                const timePart = entry.substring(firstColonIndex + 1);
                const times = timePart.split('-');
                
                if (times.length >= 2) {
                    let startTime = times[0].trim();
                    let endTime = times[1].trim();
                    
                    if (startTime && !startTime.includes(':')) {
                        startTime = startTime.padStart(2, '0') + ":00";
                    }
                    if (endTime && !endTime.includes(':')) {
                        endTime = endTime.padStart(2, '0') + ":00";
                    }
                    
                    console.log(`Day: ${day}, Start: ${startTime}, End: ${endTime}`);
                    
                    html += '<li><strong>' + day + ':</strong> ' + startTime + ' - ' + endTime + '</li>';
                    doctorScheduleData[day] = { start: startTime, end: endTime };
                }
            }
            
            html += '</ul>';
            detailsDiv.innerHTML = html;
            scheduleDiv.style.display = 'block';
            
            console.log("Parsed doctorScheduleData:", doctorScheduleData);
        } else {
            detailsDiv.innerHTML = '<p style="color:#92400e;">⚠️ No schedule set for this doctor yet.</p>';
            scheduleDiv.style.display = 'block';
        }
        
        document.getElementById('appointmentDate').value = '';
        document.getElementById('appointmentTime').innerHTML = '<option value="">— Select doctor and date first —</option>';
        document.getElementById('appointmentTime').disabled = true;
    }
    
    function checkAvailability() {
        const doctorId = document.getElementById('doctorId').value;
        const date = document.getElementById('appointmentDate').value;
        const timeSelect = document.getElementById('appointmentTime');
        
        if (!doctorId || !date) {
            timeSelect.innerHTML = '<option value="">— Select doctor and date first —</option>';
            timeSelect.disabled = true;
            return;
        }
        
        const selectedDate = new Date(date);
        const daysOfWeek = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];
        const dayOfWeek = daysOfWeek[selectedDate.getDay()];
        
        console.log("Selected date:", date, "Day:", dayOfWeek);
        
        if (!doctorScheduleData[dayOfWeek]) {
            timeSelect.innerHTML = '<option value="">❌ Doctor not available on ' + dayOfWeek + 's</option>';
            timeSelect.disabled = true;
            return;
        }
        
        timeSelect.disabled = false;
        timeSelect.innerHTML = '<option value="">Checking availability...</option>';
        
        // FIXED: Use context path for correct URL
        const url = '${pageContext.request.contextPath}/CheckAvailabilityServlet?doctorId=' + doctorId + '&date=' + date;
        
        console.log("Fetching URL:", url);
        
        fetch(url)
            .then(function(response) {
                console.log("Response status:", response.status);
                if (!response.ok) {
                    throw new Error('HTTP error! status: ' + response.status);
                }
                return response.json();
            })
            .then(function(data) {
                console.log("Received data:", data);
                
                const schedule = doctorScheduleData[dayOfWeek];
                if (!schedule) {
                    timeSelect.innerHTML = '<option value="">Doctor not available on this day</option>';
                    return;
                }
                
                if (!schedule.start || !schedule.end) {
                    console.error("Schedule missing start or end time:", schedule);
                    timeSelect.innerHTML = '<option value="">Invalid schedule for this day</option>';
                    return;
                }
                
                let startTime = schedule.start;
                let endTime = schedule.end;
                
                let startHour = 9, startMinute = 0, endHour = 17, endMinute = 0;
                
                if (startTime && startTime.includes(':')) {
                    startHour = parseInt(startTime.split(':')[0]);
                    startMinute = parseInt(startTime.split(':')[1] || 0);
                } else if (startTime) {
                    startHour = parseInt(startTime);
                    startMinute = 0;
                }
                
                if (endTime && endTime.includes(':')) {
                    endHour = parseInt(endTime.split(':')[0]);
                    endMinute = parseInt(endTime.split(':')[1] || 0);
                } else if (endTime) {
                    endHour = parseInt(endTime);
                    endMinute = 0;
                }
                
                if (isNaN(startHour)) startHour = 9;
                if (isNaN(startMinute)) startMinute = 0;
                if (isNaN(endHour)) endHour = 17;
                if (isNaN(endMinute)) endMinute = 0;
                
                const allPossibleSlots = [];
                let currentHour = startHour;
                let currentMinute = startMinute;
                
                if (currentMinute > 0 && currentMinute < 30) {
                    currentMinute = 30;
                } else if (currentMinute > 30) {
                    currentHour++;
                    currentMinute = 0;
                }
                
                let maxIterations = 100;
                let iterations = 0;
                
                while ((currentHour < endHour || (currentHour === endHour && currentMinute < endMinute)) && iterations < maxIterations) {
                    const timeString = (currentHour < 10 ? '0' + currentHour : currentHour) + ':' + (currentMinute < 10 ? '0' + currentMinute : currentMinute);
                    allPossibleSlots.push(timeString);
                    
                    currentMinute += 30;
                    if (currentMinute >= 60) {
                        currentHour++;
                        currentMinute -= 60;
                    }
                    iterations++;
                }
                
                let options = '<option value="">— Select time —</option>';
                
                if (allPossibleSlots.length === 0) {
                    options = '<option value="">No available time slots for this day</option>';
                } else {
                    for (var i = 0; i < allPossibleSlots.length; i++) {
                        var slot = allPossibleSlots[i];
                        if (data.availableSlots && data.availableSlots.indexOf(slot) !== -1) {
                            options += '<option value="' + slot + '">' + slot + '</option>';
                        } else {
                            options += '<option value="' + slot + '" disabled style="color:#999;background:#f5f5f5;">' + slot + ' (Booked)</option>';
                        }
                    }
                }
                
                timeSelect.innerHTML = options;
                timeSelect.disabled = false;
            })
            .catch(function(error) {
                console.error('Error details:', error);
                timeSelect.disabled = false;
                timeSelect.innerHTML = '<option value="">Error loading times. Please refresh and try again.</option>';
            });
    }
    
    // Prevent double submission and show loading state
    document.getElementById('appointmentForm').addEventListener('submit', function(e) {
        const submitBtn = document.getElementById('submitBtn');
        if (submitBtn.disabled) {
            e.preventDefault();
            return;
        }
        
        submitBtn.disabled = true;
        submitBtn.innerHTML = '<i class="fas fa-spinner fa-spin"></i> Processing...';
    });
    
    // Initialize event listeners
    document.addEventListener('DOMContentLoaded', function() {
        const dateInput = document.getElementById('appointmentDate');
        if (dateInput) {
            dateInput.addEventListener('change', checkAvailability);
        }
        
        const doctorSelect = document.getElementById('doctorId');
        if (doctorSelect) {
            doctorSelect.addEventListener('change', function() {
                const timeSelect = document.getElementById('appointmentTime');
                timeSelect.innerHTML = '<option value="">— Select date first —</option>';
                timeSelect.disabled = true;
                document.getElementById('appointmentDate').value = '';
            });
        }
    });
</script>
                    
</body>
</html>