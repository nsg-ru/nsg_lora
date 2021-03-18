defmodule NsgLora.Config do
  def phy(name) do
    cfg = %{
      nsglora_spi: ~S"""
      {
        "antenna_gain": 0,
        "clksrc": 0,
        "lorawan_public": true,
        "radio_0": {
          "enable": true,
          "freq": 867500000,
          "rssi_offset": -165,
          "tx_enable": true,
          "tx_freq_max": 870000000,
          "tx_freq_min": 863000000,
          "type": "SX1257"
        },
        "radio_1": {
          "enable": true,
          "freq": 868500000,
          "rssi_offset": -165,
          "tx_enable": false,
          "type": "SX1257"
          },
        "chan_FSK": {
          "bandwidth": 125000,
          "datarate": 50000,
          "enable": true,
          "freq_deviation": 25000,
          "if": 300000,
          "radio": 1
        },
        "chan_Lora_std": {
          "bandwidth": 250000,
          "enable": true,
          "if": -200000,
          "radio": 1,
          "spread_factor": 7
        },
        "chan_multiSF_0": {
          "enable": true,
          "if": -400000,
          "radio": 1
        },
        "chan_multiSF_1": {
          "enable": true,
          "if": -200000,
          "radio": 1
        },
        "chan_multiSF_2": {
          "enable": true,
          "if": 0,
          "radio": 1
        },
        "chan_multiSF_3": {
          "enable": true,
          "if": -400000,
          "radio": 0
        },
        "chan_multiSF_4": {
          "enable": true,
          "if": -200000,
          "radio": 0
        },
        "chan_multiSF_5": {
          "enable": true,
          "if": 0,
          "radio": 0
        },
        "chan_multiSF_6": {
          "enable": true,
          "if": 200000,
          "radio": 0
        },
        "chan_multiSF_7": {
          "enable": true,
          "if": 400000,
          "radio": 0
        },
        "tx_lut_0": {
          "dig_gain": 3,
          "mix_gain": 8,
          "pa_gain": 0,
          "rf_power": -6
        },
        "tx_lut_1": {
          "dig_gain": 3,
          "mix_gain": 10,
          "pa_gain": 0,
          "rf_power": -3
        },
        "tx_lut_10": {
          "dig_gain": 3,
          "mix_gain": 11,
          "pa_gain": 2,
          "rf_power": 16
        },
        "tx_lut_11": {
          "dig_gain": 3,
          "mix_gain": 10,
          "pa_gain": 3,
          "rf_power": 20
        },
        "tx_lut_12": {
          "dig_gain": 3,
          "mix_gain": 11,
          "pa_gain": 3,
          "rf_power": 23
        },
        "tx_lut_13": {
          "dig_gain": 3,
          "mix_gain": 12,
          "pa_gain": 3,
          "rf_power": 24
        },
        "tx_lut_14": {
          "dig_gain": 3,
          "mix_gain": 13,
          "pa_gain": 3,
          "rf_power": 25
        },
        "tx_lut_15": {
          "dig_gain": 3,
          "mix_gain": 15,
          "pa_gain": 3,
          "rf_power": 26
        },
        "tx_lut_2": {
          "dig_gain": 3,
          "mix_gain": 12,
          "pa_gain": 0,
          "rf_power": 0
        },
        "tx_lut_3": {
          "dig_gain": 3,
          "mix_gain": 8,
          "pa_gain": 1,
          "rf_power": 3
        },
        "tx_lut_4": {
          "dig_gain": 3,
          "mix_gain": 10,
          "pa_gain": 1,
          "rf_power": 6
        },
        "tx_lut_5": {
          "dig_gain": 3,
          "mix_gain": 12,
          "pa_gain": 1,
          "rf_power": 10
        },
        "tx_lut_6": {
          "dig_gain": 3,
          "mix_gain": 12,
          "pa_gain": 1,
          "rf_power": 11
        },
        "tx_lut_7": {
          "dig_gain": 3,
          "mix_gain": 9,
          "pa_gain": 2,
          "rf_power": 12
        },
        "tx_lut_8": {
          "dig_gain": 3,
          "mix_gain": 15,
          "pa_gain": 1,
          "rf_power": 13
        },
        "tx_lut_9": {
          "dig_gain": 3,
          "mix_gain": 10,
          "pa_gain": 2,
          "rf_power": 14
        }
      }

      """,
      rak2247_usb: ~S"""
      {
          "lorawan_public": true,
          "clksrc": 1,
          "antenna_gain": 0,
          "radio_0": {
              "enable": true,
              "type": "SX1257",
              "freq": 867500000,
              "rssi_offset": -158.0,
              "tx_enable": true,
              "tx_freq_min": 863000000,
              "tx_freq_max": 870000000
          },
          "radio_1": {
              "enable": true,
              "type": "SX1257",
              "freq": 868500000,
              "rssi_offset": -158.0,
              "tx_enable": false
          },
          "chan_multiSF_0": {
              "enable": true,
              "radio": 1,
              "if": -400000
          },
          "chan_multiSF_1": {
              "enable": true,
              "radio": 1,
              "if": -200000
          },
          "chan_multiSF_2": {
              "enable": true,
              "radio": 1,
              "if": 0
          },
          "chan_multiSF_3": {
              "enable": true,
              "radio": 0,
              "if": -400000
          },
          "chan_multiSF_4": {
              "enable": true,
              "radio": 0,
              "if": -200000
          },
          "chan_multiSF_5": {
              "enable": true,
              "radio": 0,
              "if": 0
          },
          "chan_multiSF_6": {
              "enable": true,
              "radio": 0,
              "if": 200000
          },
          "chan_multiSF_7": {
              "enable": true,
              "radio": 0,
              "if": 400000
          },
          "chan_Lora_std": {
              "enable": true,
              "radio": 1,
              "if": -200000,
              "bandwidth": 250000,
              "spread_factor": 7
          },
          "chan_FSK": {
              "enable": true,
              "radio": 1,
              "if": 300000,
              "bandwidth": 125000,
              "datarate": 50000
          },
          "tx_lut_0": {
              "pa_gain": 0,
              "mix_gain": 10,
              "rf_power": -6,
              "dig_gain": 0
          },
          "tx_lut_1": {
              "pa_gain": 0,
              "mix_gain": 14,
              "rf_power": -3,
              "dig_gain": 0
          },
          "tx_lut_2": {
              "pa_gain": 1,
              "mix_gain": 8,
              "rf_power": 0,
              "dig_gain": 3
          },
          "tx_lut_3": {
              "pa_gain": 2,
              "mix_gain": 9,
              "rf_power": 3,
              "dig_gain": 3
          },
          "tx_lut_4": {
              "pa_gain": 1,
              "mix_gain": 9,
              "rf_power": 6,
              "dig_gain": 1
          },
          "tx_lut_5": {
              "pa_gain": 2,
              "mix_gain": 9,
              "rf_power": 10,
              "dig_gain": 0
          },
          "tx_lut_6": {
              "pa_gain": 2,
              "mix_gain": 10,
              "rf_power": 11,
              "dig_gain": 0
          },
          "tx_lut_7": {
              "pa_gain": 2,
              "mix_gain": 11,
              "rf_power": 12,
              "dig_gain": 0
          },
          "tx_lut_8": {
              "pa_gain": 2,
              "mix_gain": 12,
              "rf_power": 13,
              "dig_gain": 1
          },
          "tx_lut_9": {
              "pa_gain": 2,
              "mix_gain": 12,
              "rf_power": 14,
              "dig_gain": 0
          },
          "tx_lut_10": {
              "pa_gain": 3,
              "mix_gain": 8,
              "rf_power": 16,
              "dig_gain": 1
          },
          "tx_lut_11": {
              "pa_gain": 3,
              "mix_gain": 10,
              "rf_power": 20,
              "dig_gain": 0
          },
          "tx_lut_12": {
          "desc": "TX gain table, index 12",
          "pa_gain": 3,
          "mix_gain": 12,
          "rf_power": 23,
          "dig_gain": 0
          },
          "tx_lut_13": {
          "desc": "TX gain table, index 13",
          "pa_gain": 3,
          "mix_gain": 14,
          "rf_power": 25,
          "dig_gain": 0
          },
          "tx_lut_14": {
          "desc": "TX gain table, index 14",
          "pa_gain": 3,
          "mix_gain": 14,
          "rf_power": 26,
          "dig_gain": 0
          },
          "tx_lut_15": {
          "desc": "TX gain table, index 15",
          "pa_gain": 3,
          "mix_gain": 14,
          "rf_power": 27,
          "dig_gain": 0
          }
      }
      """
    }

    cfg[name]
  end

  def gw(name) do
    cfg = %{
      default: ~S"""
      {
        "fake_gps": false,
        "forward_crc_disabled": false,
        "forward_crc_error": false,
        "forward_crc_valid": true,
        "gateway_ID": "000956FFFE3208BB",
        "keepalive_interval": 10,
        "push_timeout_ms": 100,
        "serv_port_down": 1680,
        "serv_port_up": 1680,
        "server_address": "localhost",
        "stat_interval": 30,
        "synch_word": 52
      }
      """
    }

    cfg[name]
  end
end
