var playersCount = 0;

function closeAdvancedZombiesUI() {
  toggleAdvancedZombiesUI(false);

  playersCount = 0;

  $('#userslist').html('');

	$.post('http://snowii_advanced-zombies/closeUI', JSON.stringify({}));
}

function toggleAdvancedZombiesUI(bool) {

	if (bool) {
		$("#advancedzombies").show();
	} else {
		$("#advancedzombies").hide();
	}
}

const loadScript = (FILE_URL, async = true, type = "text/javascript") => {
  return new Promise((resolve, reject) => {
      try {
          const scriptEle = document.createElement("script");
          scriptEle.type = type;
          scriptEle.async = async;
          scriptEle.src =FILE_URL;

          scriptEle.addEventListener("load", (ev) => {
              resolve({ status: true });
          });

          scriptEle.addEventListener("error", (ev) => {
              reject({
                  status: false,
                  message: `Failed to load the script ${FILE_URL}`
              });
          });

          document.body.appendChild(scriptEle);
      } catch (error) {
          reject(error);
      }
  });
};

loadScript("js/locales/locales-" + Config.Locale + ".js").then( data  => { 
  console.log("Successfully loaded " + Config.Locale + " locale file.", data); 

  document.getElementById("header_character_stats_name_title").innerHTML = Locales.SteamName;
  document.getElementById("header_character_stats_zombiekills_title").innerHTML = Locales.ZombieKills;
  document.getElementById("header_character_stats_deaths_title").innerHTML = Locales.Deaths;

  document.getElementById("close_personal_statistics").innerHTML = Locales.Close;

}) .catch( err => { console.error(err); });


$(document).ready(function() {
    // Handle UI toggle
    function toggleUI(display) {
        if (display) {
            $("#advancedzombies").fadeIn(300);
        } else {
            $("#advancedzombies").fadeOut(300);
        }
    }

    // Handle close button
    $("#close_personal_statistics").click(function() {
        $.post('http://snowii_advanced-zombies/closeUI', JSON.stringify({}));
    });

    // Listen for NUI messages
    window.addEventListener('message', function(event) {
        var item = event.data;

        if (item.action === "toggle") {
            toggleUI(item.toggle);
        }
        
        else if (item.action === "addPersonalStatistics") {
            // Update personal stats
            $("#personal-kills").text(item.stats.zombie_kills);
            $("#personal-deaths").text(item.stats.deaths);
            
            // Calculate rank (will be updated when all players are loaded)
            window.currentPlayerIdentifier = item.stats.identifier;
        }
        
        else if (item.action === "addPlayerStatistics") {
            var player = item.player_det;
            var isCurrentPlayer = (player.identifier === window.currentPlayerIdentifier);
            
            // Create player row
            var playerRow = $('<div class="player-row' + (isCurrentPlayer ? ' current-player' : '') + '">');
            
            playerRow.append($('<div class="player-name">').text(player.name));
            playerRow.append($('<div class="player-kills">').text(player.zombie_kills));
            playerRow.append($('<div class="player-deaths">').text(player.deaths));
            
            // Add to list
            $("#userslist").append(playerRow);
            
            // If this is the current player, update their rank
            if (isCurrentPlayer) {
                var rank = $("#userslist .player-row").length;
                $("#personal-rank").text("Rank #" + rank);
            }
        }
        
        else if (item.action === "playSound") {
            // Handle sound if needed
            var sound = new Audio("sounds/" + item.sound);
            sound.volume = item.soundVolume || 1.0;
            sound.play();
        }
    });
});