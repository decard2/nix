{ pkgs, ... }:

{
  home.packages = with pkgs; [
    awscli2
  ];

  home.file.".aws/config".text = ''
    [default]
    region = ru-central1
    output = json
    endpoint_url = https://storage.yandexcloud.net
  '';

  home.file.".aws/credentials".text = ''
    [default]
    aws_access_key_id = YCAJEUtCSf7usR67z0sE-WrXG
    aws_secret_access_key = YCMQe284zQc8F40GFRJUqhToZPWEURCmpCbwdQH8
  '';
}
