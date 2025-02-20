window.onload = function() {
    console.log("Admin menu script loaded");

    showAdminActions();

    window.addEventListener("message", (event) => {
        console.log("NUI Message received:", event.data);
    
        const body = document.querySelector("body");
        const adminMenu = document.getElementById("admin-menu");
        const playerList = document.getElementById("sidebar-left");
        const playerActions = document.getElementById("player-actions");
        const playersContainer = document.getElementById("players");
    
        if (!adminMenu) {
            console.error("Error: admin-menu element not found!");
            return;
        }
    
        if (event.data.type === "show") {
            adminMenu.style.display = "block";
            body.classList.add("active");

            showAdminActions();
    
            // Tampilkan daftar pemain jika ada
            if (event.data.players) {
                playersContainer.innerHTML = ""; // Reset list
                event.data.players.forEach(player => {
                    let playerDiv = document.createElement("div");
                    playerDiv.classList.add("grid-item");
                    playerDiv.innerText = player.id + " | " + player.name;
                    playerDiv.onclick = function() {
                        selectPlayer(player.id, player.name);
                    };
                    playersContainer.appendChild(playerDiv);
                });
            }
    
            // Pastikan halaman pertama terlihat
            playerList.style.display = "block";
            playerActions.style.display = "none";
    
        } else if (event.data.type === "hide") {
            adminMenu.style.display = "none";
            body.classList.remove("active");
        } else if (event.data.type === "updateFreezeButton") {
            updateFreezeButton(event.data.isFrozen);
        } else if (event.data.type === "showWarning") {
            showWarning(event.data.adminName, event.data.reason);
        } else if (event.data.type === "openClothing") {
            openClothing(event.data)
        }
    });

    document.getElementById("warning-overlay").classList.add("warning-hidden");

   // Menutup menu dengan ESC
    document.addEventListener("keydown", function(event) {
        if (event.key === "Escape") {
            let warningOverlay = document.getElementById("warning-overlay");

            // Jika warning overlay sedang aktif, jangan tutup admin menu
            if (!warningOverlay.classList.contains("warning-hidden")) {
                console.log("Warning overlay is active, ignoring ESC key.");
                return;
            }

            console.log("ESC pressed, closing menu.");
            fetch(`https://${GetParentResourceName()}/close`, {
                method: "POST",
                headers: { "Content-Type": "application/json" },
                body: JSON.stringify({})
            });
        }
    });
};

function setActiveButton(activeButtonId) {
    // Hapus kelas 'active' dari semua tombol
    const buttons = document.querySelectorAll("#sidebar-menu button");
    buttons.forEach(button => {
        button.classList.remove("active");
    });

    // Tambahkan kelas 'active' ke tombol yang dipilih
    const activeButton = document.getElementById(activeButtonId);
    if (activeButton) {
        activeButton.classList.add("active");
    }
}

// Fungsi untuk menampilkan Admin Actions
function showAdminActions() {
    document.getElementById("admin-actions").style.display = "block";
    document.getElementById("player-list").style.display = "none";
    document.getElementById("player-actions").style.display = "none";

    // Tandai tombol Admin Actions sebagai aktif
    setActiveButton("admin-actions-btn");
}

// Fungsi untuk menampilkan Player List
function showPlayerList() {
    document.getElementById("admin-actions").style.display = "none";
    document.getElementById("player-list").style.display = "block";
    document.getElementById("player-actions").style.display = "none";

    // Tandai tombol Player List sebagai aktif
    setActiveButton("player-list-btn");
}

function toggleLayout() {
    const buttonContainer = document.querySelector('.button-container');
    const adminContainer = document.querySelector('.admin-container');
    const toggleButton = document.getElementById('toggle-layout-button');
    const playerList = document.getElementById("player-list");

    if (playerList && buttonContainer && adminContainer && toggleButton) {
        // Toggle class 'minimized' pada admin-container dan button-container
        adminContainer.classList.toggle('minimized');
        buttonContainer.classList.toggle('minimized');
        playerList.classList.toggle("minimized");

        // Ubah ikon panah berdasarkan state
        if (adminContainer.classList.contains('minimized')) {
            toggleButton.innerHTML = '<i class="fas fa-arrow-down"></i>'; // Panah ke bawah saat minimize
        } else {
            toggleButton.innerHTML = '<i class="fas fa-arrow-left"></i>'; // Panah ke samping saat maximize
        }
    } else {
        console.error("❌ Error: Could not find required elements!");
    }
}

function selectPlayer(playerId, playerName) {
    if (!playerId || isNaN(playerId)) {
        console.error("❌ Error: Invalid Player ID when selecting player.");
        return;
    }

    document.getElementById("selected-player").innerText = playerName;
    document.getElementById("selected-player-id").textContent = playerId;

    console.log(`📌 Selected Player: ${playerName} (ID: ${playerId})`);

    document.getElementById("player-list").style.display = "none";
    document.getElementById("player-actions").style.display = "block";
}

function sendAction(action) {
    let playerId = document.getElementById("selected-player-id").textContent.trim(); // Ambil ID pemain

    if (!playerId || isNaN(playerId)) {
        console.error(`❌ Error: Invalid Player ID for action '${action}'`);
        return;
    }

    console.log(`📌 Sending request for action: ${action} | Player ID: ${playerId}`);

    fetch(`https://${GetParentResourceName()}/${action}`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ playerId: playerId })
    }).then(response => {
        if (!response.ok) {
            console.error(`❌ Server error for action '${action}':`, response.statusText);
        }
    }).catch(error => {
        console.error(`❌ Fetch error for action '${action}':`, error);
    });
}

function sendAksi(action) {

    fetch(`https://${GetParentResourceName()}/${action}`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({})
    }).then(response => {
        if (!response.ok) {
            console.error(`❌ Server error for action '${action}':`, response.statusText);
        }
    }).catch(error => {
        console.error(`❌ Fetch error for action '${action}':`, error);
    });
}

// Fungsi untuk aksi admin (God Mode, Fix Vehicle, dll)
function sendAdminAction(action) {
    console.log(`📌 Sending admin action: ${action}`);

    fetch(`https://${GetParentResourceName()}/${action}`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({})
    }).then(response => {
        if (!response.ok) {
            console.error(`❌ Server error for action '${action}':`, response.statusText);
        }
    }).catch(error => {
        console.error(`❌ Fetch error for action '${action}':`, error);
    });
}

function updateFreezeButton(isFrozen) {
    const freezeButton = document.getElementById("freeze-button");
    if (isFrozen) {
        freezeButton.innerText = "❄️ Unfreeze"; // Jika frozen, tombol berubah menjadi "Unfreeze"
    } else {
        freezeButton.innerText = "❄️ Freeze"; // Jika unfrozen, tombol berubah menjadi "Freeze"
    }
}

function sendKickBan(action, reason) {
    fetch(`https://${GetParentResourceName()}/${action}`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ playerId: window.selectedPlayer, reason })
    });
}

function banPlayer() {
    let playerId = document.getElementById("selected-player-id").textContent.trim(); // Ambil ID pemain

    if (!playerId || isNaN(playerId)) {
        console.error("❌ Error: Invalid Player ID for ban!");
        return;
    }

    console.log(`📌 Opening Ban Dialog for Player ID: ${playerId}`);

    // Kirim permintaan ke NUI callback untuk membuka dialog ox_lib
    fetch(`https://${GetParentResourceName()}/openBanDialog`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ playerId })
    }).then(response => {
        if (!response.ok) {
            console.error("❌ Error:", response.statusText);
        }
    }).catch(error => {
        console.error("❌ Error:", error);
    });
}

function openWarnForm() {
    let playerId = document.getElementById("selected-player-id").textContent.trim();

    if (!playerId || isNaN(playerId)) {
        console.error("❌ Error: Invalid Player ID for Warning!");
        return;
    }

    // Kirim permintaan ke NUI Callback untuk membuka dialog
    fetch(`https://${GetParentResourceName()}/ox_lib_dialog`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
            title: "⚠️ Issue Warning",
            description: "Enter the reason for warning"
        })
    })
    .then(response => response.json())
    .then(data => {
        if (data && data.input) {
            sendWarn(playerId, data.input); // Kirim reason ke server
        }
    })
    .catch(error => console.error("❌ Error:", error));
}


function sendWarn(playerId, reason) {
    console.log(`📌 Sending warning to Player ID: ${playerId} | Reason: ${reason}`);

    fetch(`https://${GetParentResourceName()}/warnPlayer`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ playerId, reason })
    });

    // Tampilkan efek warning di layar
    showWarning("Admin", reason);
}

function showWarning(adminName, reason) {
    let warningOverlay = document.getElementById("warning-overlay");
    let adminText = document.getElementById("warning-admin");
    let reasonText = document.getElementById("warning-reason");
    let warningTimer = document.getElementById("warning-timer");

    adminText.innerText = "Warning by: " + adminName;
    reasonText.innerText = "Reason: " + reason;

    warningOverlay.classList.remove("warning-hidden");
    warningTimer.classList.remove("warning-timer-hidden");

    let timeLeft = 10;
    warningTimer.innerText = "Wait For " + timeLeft + "s";

    let countdown = setInterval(() => {
        timeLeft--;
        warningTimer.innerText = "Wait For " + timeLeft + "s";

        if (timeLeft <= 0) {
            clearInterval(countdown);
            warningOverlay.classList.add("warning-hidden");
            warningTimer.classList.add("warning-timer-hidden");
        }
    }, 1000);

    document.addEventListener("keydown", blockEscForWarning);

    setTimeout(() => {
        warningOverlay.classList.add("warning-hidden");
        warningTimer.classList.add("warning-timer-hidden");
        document.removeEventListener("keydown", blockEscForWarning);
    }, 10000);
}


function closeAdminMenu() {
    const adminMenu = document.getElementById("admin-menu");
    const warningOverlay = document.getElementById("warning-overlay");

    if (adminMenu) {
        // Tambahkan class 'closing' untuk memicu efek transisi
        adminMenu.classList.add("closing");

        // Tunggu hingga transisi selesai sebelum menyembunyikan menu
        setTimeout(() => {
            adminMenu.style.display = "none";
            adminMenu.classList.remove("closing"); // Hapus class 'closing'
            document.body.classList.remove("active");
        }, 300); // Sesuaikan waktu dengan durasi transisi (300ms)
    }

    // Pastikan Warning Overlay tidak ikut tertutup
    if (!warningOverlay.classList.contains("warning-hidden")) {
        return;
    }

    // Kirim permintaan ke server untuk menutup menu
    fetch(`https://${GetParentResourceName()}/close`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({})
    });
}

function openClothing() {
    let playerId = document.getElementById("selected-player-id").textContent.trim();

    if (!playerId || isNaN(playerId)) {
        console.error("❌ Error: Invalid Player ID for Clothing Menu!");
        return;
    }

    console.log(`📌 Opening Clothing Menu for Player ID: ${playerId}`);

    // Kirim permintaan untuk membuka menu pakaian
    fetch(`https://${GetParentResourceName()}/openClothing`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ playerId })
    }).then(response => {
        if (response.ok) {
            // Tutup menu admin setelah menu pakaian dibuka
            closeAdminMenu();
        }
    }).catch(error => {
        console.error("❌ Error:", error);
    });
}

function openInventory() {
    let playerId = document.getElementById("selected-player-id").textContent.trim(); // Ambil ID pemain

    if (!playerId || isNaN(playerId)) {
        console.error("❌ Error: Invalid Player ID for Open Inventory!");
        return;
    }

    console.log(`📌 Opening Inventory for Player ID: ${playerId}`);

    // Tutup UI admin menu
    closeAdminMenu();

    // Kirim permintaan untuk membuka inventory
    fetch(`https://${GetParentResourceName()}/openInventory`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ playerId })
    }).then(response => {
        if (!response.ok) {
            console.error("❌ Error:", response.statusText);
        }
    }).catch(error => {
        console.error("❌ Error:", error);
    });
}

function toggleSidebar() {
    const sidebar = document.getElementById("sidebar-navigation");
    sidebar.classList.toggle("collapsed");
}


function spawnVehicle() {
    fetch(`https://${GetParentResourceName()}/spawnvehicle`, {
        method: "POST",
        headers: { "Content-Type": "application/json" }
    });
}

function changeWeather() {
    fetch(`https://${GetParentResourceName()}/openWeatherDialog`, {
        method: "POST",
        headers: { "Content-Type": "application/json" }
    }).then(response => response.json())
      .then(data => {
          if (data && data.weatherType) {
              fetch(`https://${GetParentResourceName()}/changeWeather`, {
                  method: "POST",
                  headers: { "Content-Type": "application/json" },
                  body: JSON.stringify({ weatherType: data.weatherType })
              });
          }
      }).catch(error => console.error("❌ Error:", error));
}

function changeTime() {
    console.log("📌 Change Time button clicked.");

    fetch(`https://${GetParentResourceName()}/openTimeDialog`, {
        method: "POST",
        headers: { "Content-Type": "application/json" }
    })
    .then(response => response.json())
    .then(data => {
        if (data && typeof data.hour === "number" && typeof data.minute === "number") {
            console.log("📌 Sending time to server. Hour:", data.hour, "Minute:", data.minute);
            return fetch(`https://${GetParentResourceName()}/changeTime`, { // Tambahkan return
                method: "POST",
                headers: { "Content-Type": "application/json" },
                body: JSON.stringify({ hour: data.hour, minute: data.minute })
            });
        } else {
            console.log("❌ User canceled time selection.");
        }
    })
    .catch(error => console.error("❌ Error:", error));
}


function goBack() {
    document.getElementById("player-list").style.display = "block";
    document.getElementById("player-actions").style.display = "none";
}