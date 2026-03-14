import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Services.UI

Item {
  id: root

  property var pluginApi: null

  // Slot symbols
  readonly property int cloverGain: 1
  readonly property var symbols: [
      // Common
      {
          icon: "poo-filled",
          label: "Poo",
          weight: 21,
          gain: 0
      },
      {
          icon: "cherry-filled",
          label: "Cherry",
          weight: 19,
          gain: 1
      },
      {
          icon: "lemon-2-filled",
          label: "Lemon",
          weight: 16,
          gain: 2
      },
      {
          icon: "melon-filled",
          label: "Melon",
          weight: 14,
          gain: 3
      },
      {
          icon: "bell-filled",
          label: "Bell",
          weight: 12,
          gain: 4
      },
      {
          icon: "clover-filled",
          label: "Clover",
          color: "lightgreen",
          weight: 8,
          gain: cloverGain
      },
      {
          icon: "diamond-filled",
          label: "Diamond",
          weight: 6,
          gain: 5
      },
      // HAKARI DOMAIN EXPANSION SKIBIDI DOP DOP YES YES
      {
          icon: "play-card-7-filled",
          label: "7",
          color: "#FFD700",
          weight: 4,
          gain: 8
      }
  ]

    /* Gain table :
       777: 77 credits
       Two  of a kind: Symbol gain
       Tree of a kind: Symbol gain * 2

       Clover is a joker:
       1 clover               : cloverGain
       1 clover  + 2 of a kind: cloverGain     + symbol Tree of a kind
       2 clovers + 1 symbol   : cloverGain * 2 + symbol Tree of a kind
       3 clovers              : cloverGain * 5
    */

  // Game state
  property int reel0: pluginApi?.pluginSettings?.reel0 ?? 0
  property int reel1: pluginApi?.pluginSettings?.reel1 ?? 0
  property int reel2: pluginApi?.pluginSettings?.reel2 ?? 0
  property bool spinning: false
  property bool winDelayActive: false
  property bool withClovers: false // Did we win with or without clovers ?
  property int lastGain: 0
  property string lastResult: "" // "jackpot" | "win" | "poowin" | "smallwin" | "loss"
  property int spinSerial: 0 // increments every spin so Panel always sees a change
  // Pre-picked results, revealed reel-by-reel as each stops
  property int pendingReel0: 0
  property int pendingReel1: 0
  property int pendingReel2: 0
  property int credits: pluginApi?.pluginSettings?.credits ?? 15
  property int totalSpins: pluginApi?.pluginSettings?.totalSpins ?? 0
  property int totalWins: pluginApi?.pluginSettings?.totalWins ?? 0

  readonly property int totalWeight: {
      var total = 0;
      for (var i = 0; i < symbols.length; i++)
          total += symbols[i].weight;
      return total;
  }

  // Weighted random pick
  function weightedPick() {
      var r = Math.random() * totalWeight;
      var acc = 0;
      for (var j = 0; j < symbols.length; j++) {
          acc += symbols[j].weight;
          if (r < acc)
              return j;
      }
      return symbols.length - 1;
  }

  // Spin
  function spin() {
    if (spinning)
      return;
    if (winDelayActive)
      return;
    if (credits <= 0) {
      ToastService.showError("No credits left! Reset to play again.");
      return;
    }
    // Pre-pick all three results now so each reel can reveal its
    // correct symbol the moment it stops, not after all three land
    pendingReel0 = weightedPick();
    pendingReel1 = weightedPick();
    pendingReel2 = weightedPick();
    spinning = true;
    credits -= 1;
    totalSpins += 1;
    spinTimer.restart();
  }

  // Called by Panel staggered timers as each reel stops
  function landReel(reelIdx) {
    if (reelIdx === 0)
      reel0 = pendingReel0;
    else if (reelIdx === 1)
      reel1 = pendingReel1;
    else if (reelIdx === 2)
      reel2 = pendingReel2;
  }

  function landReels() {
    // All reels have already been assigned by landReel() calls.
    // Just resolve the result.
    var results = [symbols[reel0], symbols[reel1], symbols[reel2]];

    // Count occurrences of each symbol
    const symbolCount = {};
    results.forEach(symbol => {
      symbolCount[symbol.label] = (symbolCount[symbol.label] || 0) + 1;
    });

    var result;
    let gain = 0;
    let clovers = symbolCount["Clover"] || 0;

    for (const [label, count] of Object.entries(symbolCount)) {
      const symbol = symbols.find(s => s.label === label);
      if (count === 3) { // 3 of a kind
        if (symbol.label === "7") { // Jackpot !!!
          gain += 77;
          result = "jackpot";
        } else if (symbol.label === "Clover") { // Special clover case
          gain += symbol.gain * 5;
          result = "win";
        } else { // Regular 3 of a kind
          gain += symbol.gain * 2;
          result = symbol.label !== "Poo" ? "win" : "poowin";
        }
        break; // Nothing more to compute
      }
        // 2 of a kind, clovers count as jokers here
      else if (symbol.label !== "Clover" && count === 2) {
        if (clovers === 1) { // Becomes a 3 of a kind
          gain += symbol.gain * 2;
          result = symbol.label !== "Poo" ? "win" : "smallwin"
        } else { // Regular 2 of a kind
          gain += symbol.gain;
          result = symbol.label !== "Poo" ? "smallwin" : "lose";
        }
        break; // Nothing more to compute
      }
      // Special 3 of a kind : 2 clovers + 1 symbol
      else if (symbol.label !== "Clover" && clovers === 2) {
        gain += symbol.gain * 2;
        result = symbol.label !== "Poo" ? "win" : "smallwin"
        break; // Nothing more to compute
      }
    }

    if (clovers > 0 && clovers < 3){
        gain += clovers * cloverGain;
        result = result || "smallwin";
    }

    if (gain === 0){
        result = result || "loss";
    } else {
        credits += gain;
        totalWins += 1;
        winDelayActive = true;
        winDelayTimer.restart();
    }

    spinning = false;
    lastResult = result;
    lastGain = gain;
    withClovers = clovers !== 0;
    spinSerial += 1;

    saveState();
  }

  function resetCredits() {
    if (credits > 0)
      return;
    if (spinning)
      return;
    credits = 15;
    lastResult = "";
    lastGain = 0;
    withClovers = false;
    spinSerial = 0;
    saveState();
    ToastService.showNotice("Credits reset to 15");
  }

  function do_stats(spins){
    let beforeCredits = credits;
    console.log("Before: ", beforeCredits);
    for (var i = 0; i < spins; i++){
      pendingReel0 = weightedPick();
      pendingReel1 = weightedPick();
      pendingReel2 = weightedPick();
      credits -= 1;
      landReel(0);
      landReel(1);
      landReel(2);
      landReels();
    }
    console.log("After: ", credits);
    console.log("Average per spin: ", (credits - beforeCredits) / spins);
    credits = 0;
    totalSpins = 0;
    resetCredits();
  }

  function saveState() {
    if (!pluginApi)
      return;
    pluginApi.pluginSettings.credits = credits;
    pluginApi.pluginSettings.totalSpins = totalSpins;
    pluginApi.pluginSettings.totalWins = totalWins;
    pluginApi.pluginSettings.reel0 = reel0;
    pluginApi.pluginSettings.reel1 = reel1;
    pluginApi.pluginSettings.reel2 = reel2;
    pluginApi.saveSettings();
  }

  // Staggered reel timers (live in Main so they work panel-open or closed)
  // Reel 0 stops first, then 1, then 2. Each reveals its result on stop.
  // Total duration 600+400+300 = 1300ms matches Panel's visual stagger.
  Timer {
    id: spinTimer // kept as spinTimer so spin() can call spinTimer.restart()
    interval: 600
    repeat: false
    onTriggered: {
      root.landReel(0);
      stagger1.restart();
    }
  }
  Timer {
    id: stagger1
    interval: 400
    repeat: false
    onTriggered: {
      root.landReel(1);
      stagger2.restart();
    }
  }
  Timer {
    id: stagger2
    interval: 300
    repeat: false
    onTriggered: {
      root.landReel(2);
      root.landReels();
    }
  }

  Timer {
    id: winDelayTimer
    interval: 1000
    repeat: false
    onTriggered: {
      root.winDelayActive = false;
    }
  }

  // IPC
  // Timer to delay spin until after the panel has had time to open
  Timer {
    id: ipcSpinDelay
    interval: 350
    repeat: false
    onTriggered: root.spin()
  }

  IpcHandler {
    target: "plugin:slot-machine"

    function spin() {
      if (!pluginApi)
        return;
      if (root.winDelayActive)
        return;
      if (pluginApi.panelOpenScreen) {
        // Panel already open — spin immediately
        root.spin();
      } else {
        // Panel closed — open it first then spin after delay
        pluginApi.withCurrentScreen(screen => {
                                      pluginApi.openPanel(screen);
                                    });
        ipcSpinDelay.restart();
      }
    }

    function toggle() {
      if (!pluginApi)
        return;
      pluginApi.withCurrentScreen(screen => {
                                    pluginApi.togglePanel(screen);
                                  });
    }

    function reset() {
      root.resetCredits();
    }

    function do_stats(spins: int) {
      root.do_stats(spins);
    }
  }

  Component.onCompleted: {
    Logger.i("SlotMachine", "Plugin loaded. Credits:", credits);
  }
}
