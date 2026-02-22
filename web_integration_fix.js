// // REPLACE the existing JavaScript in doctorsreport.php with this:

// let userLat = null, userLng = null;
// let useTP = <?php echo isset($_SESSION['use_tp']) ? (int)$_SESSION['use_tp'] : 0; ?>;

// const isFlutterApp = !!window.FlutterChannel;

// $("#user_lat").val("Detecting...");
// $("#user_lng").val("Detecting...");
// $("#gps_status").html(
//   `<span class="spinner-border spinner-border-sm"></span> Getting location...`
// );

// // Decide who handles GPS
// if (isFlutterApp) {
//   getLocationFromFlutter();
// } else {
//   getLocationFromBrowser();
// }

// // 🌐 Browser GPS
// function getLocationFromBrowser() {
//   if (!navigator.geolocation) {
//     $("#gps_status").html(`<span class="text-danger">❌ Location not supported</span>`);
//     return;
//   }

//   navigator.geolocation.getCurrentPosition(
//     function (pos) {
//       setLocation(pos.coords.latitude, pos.coords.longitude);
//     },
//     function (err) {
//       $("#gps_status").html(`<span class="text-danger">❌ ${err.message}</span>`);
//     },
//     { timeout: 10000, enableHighAccuracy: true }
//   );
// }

// // 📱 Ask Flutter for GPS
// function getLocationFromFlutter() {
//   $("#gps_status").html(
//     `<span class="spinner-border spinner-border-sm"></span> Getting location from Flutter...`
//   );

//   window.FlutterChannel.postMessage(
//     JSON.stringify({ action: "getLocation" })
//   );

//   // ⏰ Add timeout for Flutter response
//   setTimeout(() => {
//     if (!userLat || !userLng) {
//       $("#gps_status").html(
//         `<span class="text-danger">❌ Flutter location timeout</span>`
//       );
//     }
//   }, 15000);
// }

// // Set values
// function setLocation(lat, lng) {
//   userLat = lat;
//   userLng = lng;

//   $("#user_lat").val(lat);
//   $("#user_lng").val(lng);
//   $("#gps_status").html(`<span class="text-success">📍 Location detected</span>`);
// }

// // ✅ CORRECT: Handle Flutter responses via the function Flutter creates
// // This will be called by Flutter's _setupWebResponseHandler()
// window.handleFlutterResponse = function(response) {
//   try {
//     const data = typeof response === 'string' ? JSON.parse(response) : response;
//     console.log('📨 Received Flutter response:', data);

//     if (data.action === 'locationResponse' && data.status === 'success') {
//       setLocation(data.data.latitude, data.data.longitude);
//     } else if (data.action === 'locationResponse' && data.status === 'error') {
//       $("#gps_status").html(
//         `<span class="text-danger">❌ ${data.error}</span>`
//       );
//     } else if (data.action === 'imageResponse' && data.status === 'success') {
//       console.log('📷 Image received:', data.data.name);
//       // Handle image display here
//     } else if (data.action === 'testConnectionResponse' && data.status === 'success') {
//       console.log('🔗 Connection test successful:', data.message);
//     }
//   } catch (error) {
//     console.error('Error parsing Flutter message:', error);
//   }
// };

// // ❌ REMOVE these conflicting listeners:
// // window.addEventListener('message', function(event) { ... }); // DELETE THIS
// // window.addEventListener("message", function (event) { ... }); // DELETE THIS
