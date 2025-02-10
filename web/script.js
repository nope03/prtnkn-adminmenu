window.onload = function() {
    console.log("Admin menu script loaded");

    window.addEventListener("message", (event) => {
        console.log("NUI Message received:", event.data);
    
        const body = document.querySelector("body");
        const adminMenu = document.getElementById("admin-menu");
        const playerList = document.getElementById("player-list");
        const playerActions = document.getElementById("player-actions");
        const playersContainer = document.getElementById("players");
    
        if (!adminMenu) {
            console.error("Error: admin-menu element not found!");
            return;
        }
    
        if (event.data.type === "show") {
            adminMenu.style.display = "block";
            body.classList.add("active");
    
            // Tampilkan daftar pemain jika ada
            if (event.data.players) {
                playersContainer.innerHTML = ""; // Reset list
                event.data.players.forEach(player => {
                    let playerDiv = document.createElement("div");
                    playerDiv.classList.add("grid-item");
                    playerDiv.innerText = player.name + " (ID: " + player.id + ")";
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
        body: JSON.stringify({ playerId })
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
    let selectedPlayerId = document.getElementById("selected-player-id").textContent.trim(); // Ambil ID

    if (!selectedPlayerId || isNaN(selectedPlayerId)) {
        console.error("❌ Error: Invalid Player ID for ban!");
        return;
    }

    console.log(`📌 Sending ban request for Player ID: ${selectedPlayerId}`);

    fetch(`https://${GetParentResourceName()}/banRequest`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ playerId: selectedPlayerId })
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
    let adminMenu = document.getElementById("admin-menu");

    if (adminMenu) {
        adminMenu.style.display = "none";
        document.body.classList.remove("active");
    }

    // **Pastikan Warning Overlay tidak ikut tertutup**
    let warningOverlay = document.getElementById("warning-overlay");
    if (!warningOverlay.classList.contains("warning-hidden")) {
        return; // Jika Warning sedang aktif, jangan tutup overlay
    }

    fetch(`https://${GetParentResourceName()}/close`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({})
    });
}

// Fungsi kembali ke daftar pemain
function goBack() {
    document.getElementById("player-list").style.display = "block";
    document.getElementById("player-actions").style.display = "none";
}
