{ config, pkgs, ... }:

{
  # Просто устанавливаем nekoray
  home.packages = with pkgs; [
    nekoray
  ];

  # Создаём конфиг в правильном месте
  xdg.configFile."nekoray/config.json".text = ''
    {
        "inbounds": [
            {
                "listen": "127.0.0.1",
                "port": 10808,
                "protocol": "socks",
                "settings": {
                    "udp": true
                }
            }
        ],
        "log": {
            "loglevel": "error"
        },
        "outbounds": [
            {
                "protocol": "vless",
                "settings": {
                    "vnext": [
                        {
                            "address": "176.120.66.106",
                            "port": 443,
                            "users": [
                                {
                                    "encryption": "none",
                                    "flow": "xtls-rprx-vision",
                                    "id": "68306898-1383-457b-8abc-ecf8c02b531a"
                                }
                            ]
                        }
                    ]
                },
                "streamSettings": {
                    "network": "tcp",
                    "realitySettings": {
                        "fingerprint": "chrome",
                        "publicKey": "ye4S8DEXIx8egIIK3i-i32d5ZMfwlLYVV9E18oIUh2Y",
                        "serverName": "www.googletagmanager.com",
                        "shortId": "29649d491819b3bc",
                        "spiderX": ""
                    },
                    "security": "reality"
                }
            }
        ]
    }
  '';
}
