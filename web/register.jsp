<%@ page contentType="text/html;charset=UTF-8" %>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Create Account – IHVS</title>
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700&display=swap" rel="stylesheet">
    <link rel="stylesheet" href="${pageContext.request.contextPath}/css/style.css">
</head>
<body>
<div class="auth-page">
    <!-- Back to home link -->
    <a href="index.jsp" class="back-home">← Back to Home</a>
    
    <div class="auth-card" style="max-width: 560px;">
        <div class="auth-header">
            <div class="auth-logo">🏥 IHVS</div>
            <h1>Create Account</h1>
            <p>Join the Intelligent Health Validation System</p>
        </div>

        <div class="auth-body">
            <% String error = (String) request.getAttribute("error"); %>
            <% if (error != null) { %>
                <div class="alert alert-error">
                    <span class="alert-icon">✕</span>
                    <%= error %>
                </div>
            <% } %>

            <!-- Role Selection -->
            <div class="form-group">
                <label class="form-label" for="roleSelect">Select Account Type</label>
                <select class="form-control" id="roleSelect" name="role" form="regForm" required onchange="toggleFields()">
                    <option value="">-- Select Role --</option>
                    <option value="patient">🩺 Patient</option>
                    <option value="doctor">👨‍⚕️ Doctor</option>
                    <option value="admin">👑 Administrator</option>
                    <option value="medicalaid">🛡️ Medical Aid Provider</option>
                </select>
            </div>

            <form method="post" action="${pageContext.request.contextPath}/RegisterServlet" id="regForm">
                <div class="form-row">
                    <div class="form-group">
                        <label class="form-label" for="fullName">Full Name</label>
                        <input type="text" class="form-control" id="fullName" name="fullName" 
                               placeholder="e.g. Thabo Nkosi" required>
                    </div>
                    <div class="form-group">
                        <label class="form-label" for="username">Username</label>
                        <input type="text" class="form-control" id="username" name="username" 
                               placeholder="Choose a username" required>
                    </div>
                </div>

                <div class="form-row">
                    <div class="form-group">
                        <label class="form-label" for="email">Email Address</label>
                        <input type="email" class="form-control" id="email" name="email" 
                               placeholder="you@example.com" required>
                    </div>
                    <div class="form-group">
                        <label class="form-label" for="phone">Phone Number</label>
                        <input type="tel" class="form-control" id="phone" name="phone" 
                               placeholder="e.g. 0821234567" required>
                    </div>
                </div>

                <div class="form-row">
                    <div class="form-group">
                        <label class="form-label" for="password">Password</label>
                        <input type="password" class="form-control" id="password" name="password" 
                               placeholder="Min. 8 characters" required minlength="8">
                    </div>
                    <div class="form-group">
                        <label class="form-label" for="confirmPassword">Confirm Password</label>
                        <input type="password" class="form-control" id="confirmPassword" name="confirmPassword" 
                               placeholder="Repeat password" required>
                    </div>
                </div>

                <!-- Doctor-only fields -->
                <div id="doctorFields" style="display:none;" class="doctor-fields">
                    <div class="form-group">
                        <label class="form-label" for="specialization">Specialization</label>
                        <select class="form-control" id="specialization" name="specialization">
                            <option value="">-- Select Specialization --</option>
                            <option value="General Practitioner">General Practitioner</option>
                            <option value="Cardiologist">Cardiologist</option>
                            <option value="Pediatrician">Pediatrician</option>
                            <option value="Dermatologist">Dermatologist</option>
                            <option value="Orthopedic">Orthopedic</option>
                            <option value="Neurologist">Neurologist</option>
                        </select>
                    </div>
                    <div class="form-group">
                        <label class="form-label" for="consultationFee">Consultation Fee (ZAR)</label>
                        <input type="number" class="form-control" id="consultationFee" name="consultationFee" 
                               placeholder="e.g. 500" min="0" step="0.01">
                    </div>
                </div>

                <!-- Admin & Medical Aid Info -->
                <div id="adminInfo" style="display:none;" class="info-box">
                    <p><strong>Note:</strong> Admin and Medical Aid accounts require activation by system administrator.</p>
                </div>

                <div class="terms-checkbox">
                    <label class="checkbox-label">
                        <input type="checkbox" required> I agree to the <a href="#">Terms of Service</a> and <a href="#">Privacy Policy</a>
                    </label>
                </div>

                <button type="submit" class="btn btn-primary btn-full btn-lg">
                    Create Account →
                </button>
            </form>

            <div class="auth-divider">
                <span>Already have an account?</span>
            </div>

            <div class="auth-footer">
                <p><a href="login.jsp" class="auth-link">Sign in to your account</a></p>
            </div>
            
           
        </div>
    </div>
</div>

<script>
function toggleFields() {
    var role = document.getElementById('roleSelect').value;
    var doctorFields = document.getElementById('doctorFields');
    var adminInfo = document.getElementById('adminInfo');
    
    doctorFields.style.display = 'none';
    if (adminInfo) adminInfo.style.display = 'none';
    
    if (role === 'doctor') {
        doctorFields.style.display = 'block';
        document.getElementById('specialization').required = true;
        document.getElementById('consultationFee').required = true;
    } else {
        document.getElementById('specialization').required = false;
        document.getElementById('consultationFee').required = false;
    }
    
    if (role === 'admin' || role === 'medicalaid') {
        if (adminInfo) adminInfo.style.display = 'block';
    }
}

document.getElementById('confirmPassword').addEventListener('input', function() {
    var password = document.getElementById('password').value;
    var confirm = this.value;
    
    if (confirm.length > 0) {
        this.setCustomValidity(password === confirm ? '' : 'Passwords do not match');
    }
});
</script>
</body>
</html>