{ config, pkgs, ... }:
{
  home.packages = with pkgs; [
    btop
    pciutils
    neofetch
    unzip
    kubectl
    kubernetes-helm
    s3cmd
  ];
  programs.git = {
    enable = true;
    userName = "Decard";
    userEmail = "mail@dayreon.ru";
  };
  programs.zsh = {
    enable = true;
    oh-my-zsh = {
      enable = true;
      theme = "refined";
      plugins = [ "kubectl" "helm" ];
    };
  };
  programs.kitty = {
    enable = true;
    settings = {
      font_size = 16;
      background_opacity = "0.75";
    };
  };

  home.file.".s3cfg".text = ''    
    [default]
    access_key = YCAJEUtCSf7usR67z0sE-WrXG
    access_token = 
    add_encoding_exts = 
    add_headers = 
    bucket_location = ru-central1
    ca_certs_file = 
    cache_file = 
    check_ssl_certificate = True
    check_ssl_hostname = True
    cloudfront_host = cloudfront.amazonaws.com
    connection_max_age = 5
    connection_pooling = True
    content_disposition = 
    content_type = 
    default_mime_type = binary/octet-stream
    delay_updates = False
    delete_after = False
    delete_after_fetch = False
    delete_removed = False
    dry_run = False
    enable_multipart = True
    encoding = UTF-8
    encrypt = False
    expiry_date = 
    expiry_days = 
    expiry_prefix = 
    follow_symlinks = False
    force = False
    get_continue = False
    gpg_command = None
    gpg_decrypt = %(gpg_command)s -d --verbose --no-use-agent --batch --yes --passphrase-fd %(passphrase_fd)s -o %(output_file)s %(input_file)s
    gpg_encrypt = %(gpg_command)s -c --verbose --no-use-agent --batch --yes --passphrase-fd %(passphrase_fd)s -o %(output_file)s %(input_file)s
    gpg_passphrase = 
    guess_mime_type = True
    host_base = storage.yandexcloud.net
    host_bucket = %(bucket)s.storage.yandexcloud.net
    human_readable_sizes = False
    invalidate_default_index_on_cf = False
    invalidate_default_index_root_on_cf = True
    invalidate_on_cf = False
    kms_key = 
    limit = -1
    limitrate = 0
    list_allow_unordered = False
    list_md5 = False
    log_target_prefix = 
    long_listing = False
    max_delete = -1
    mime_type = 
    multipart_chunk_size_mb = 15
    multipart_copy_chunk_size_mb = 1024
    multipart_max_chunks = 10000
    preserve_attrs = True
    progress_meter = True
    proxy_host = 
    proxy_port = 0
    public_url_use_https = False
    put_continue = False
    recursive = False
    recv_chunk = 65536
    reduced_redundancy = False
    requester_pays = False
    restore_days = 1
    restore_priority = Standard
    secret_key = YCMQe284zQc8F40GFRJUqhToZPWEURCmpCbwdQH8
    send_chunk = 65536
    server_side_encryption = False
    signature_v2 = False
    signurl_use_https = False
    simpledb_host = sdb.amazonaws.com
    skip_existing = False
    socket_timeout = 300
    ssl_client_cert_file = 
    ssl_client_key_file = 
    stats = False
    stop_on_error = False
    storage_class = 
    throttle_max = 100
    upload_id = 
    urlencoding_mode = normal
    use_http_expect = False
    use_https = True
    use_mime_magic = True
    verbosity = WARNING
    website_error = 
    website_index = index.html
    website_endpoint = http://%(bucket)s.website.yandexcloud.net
  '';

  home.file."kubeconfig" = {
    text = ''
      apiVersion: v1
      clusters:
      - cluster:
          certificate-authority-data: LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCk1JSUJkakNDQVIyZ0F3SUJBZ0lCQURBS0JnZ3Foa2pPUFFRREFqQWpNU0V3SHdZRFZRUUREQmhyTTNNdGMyVnkKZG1WeUxXTmhRREUyT0RJeE9USTBNREV3SGhjTk1qTXdOREl5TVRrME1EQXhXaGNOTXpNd05ERTVNVGswTURBeApXakFqTVNFd0h3WURWUVFEREJock0zTXRjMlZ5ZG1WeUxXTmhRREUyT0RJeE9USTBNREV3V1RBVEJnY3Foa2pPClBRSUJCZ2dxaGtqT1BRTUJCd05DQUFSZkhYalJidzJHdW9ZNFJPNlRDRDkvNHlLU0VydHVzQUtiR0JTRGVxeGsKZm81ZHJjTkc4MGI4MUdhb2JMVkE2UHJIOWxKdnRkTkozRityNjNnVmwxOHhvMEl3UURBT0JnTlZIUThCQWY4RQpCQU1DQXFRd0R3WURWUjBUQVFIL0JBVXdBd0VCL3pBZEJnTlZIUTRFRmdRVXRmNUwxdmdDRW15c2U0Y0ViYWs0Cm4xSzhaYk13Q2dZSUtvWkl6ajBFQXdJRFJ3QXdSQUlnUGF3Y3VEaWsvVWdzbjFMS3JlQ1U3c0tUZm9TOFFnZUkKNW5UWjBjWHlYQmtDSUJxZ3dOTEdmR0RXeWJ2TlJQM2RGRFdidXkwL1l5ZC96cHpzVDRPSjllY2MKLS0tLS1FTkQgQ0VSVElGSUNBVEUtLS0tLQo=
          server: https://51.250.83.89:6443
        name: default
      contexts:
      - context:
          cluster: default
          user: default
        name: default
      current-context: default
      kind: Config
      preferences: {}
      users:
      - name: default
        user:
          client-certificate-data: LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCk1JSUJrRENDQVRlZ0F3SUJBZ0lJSk5ObTlQTkFzWmN3Q2dZSUtvWkl6ajBFQXdJd0l6RWhNQjhHQTFVRUF3d1kKYXpOekxXTnNhV1Z1ZEMxallVQXhOamd5TVRreU5EQXhNQjRYRFRJek1EUXlNakU1TkRBd01Wb1hEVEkwTURReQpNVEU1TkRBd01Wb3dNREVYTUJVR0ExVUVDaE1PYzNsemRHVnRPbTFoYzNSbGNuTXhGVEFUQmdOVkJBTVRESE41CmMzUmxiVHBoWkcxcGJqQlpNQk1HQnlxR1NNNDlBZ0VHQ0NxR1NNNDlBd0VIQTBJQUJLWVJOVnQzUXF3MlVlZkUKUmxqQ0FtdWExZ1R2YTNVWnIxVmFBVm10Mm5yYmx5L2ZESks1Zzh6QzQ1QnA1bGo4MUNGVDB0cGtMSUV2MmZHNgpDcDFvNXp1alNEQkdNQTRHQTFVZER3RUIvd1FFQXdJRm9EQVRCZ05WSFNVRUREQUtCZ2dyQmdFRkJRY0RBakFmCkJnTlZIU01FR0RBV2dCVDFWVVh1S2ZlOHVnZWI3K21Sd3UwREt6L3MyekFLQmdncWhrak9QUVFEQWdOSEFEQkUKQWlCU2xkUlRWTVVtM2RLQXVWQnVRZVBvVjhERWI4L1NNT2lzSm00WEpXTWplQUlnVUpGTU9BZ2tCNHF5eTlyMAoyNjZBL0tST0tOcUdpb2xNMkR4MFZFdmpTWFE9Ci0tLS0tRU5EIENFUlRJRklDQVRFLS0tLS0KLS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCk1JSUJkakNDQVIyZ0F3SUJBZ0lCQURBS0JnZ3Foa2pPUFFRREFqQWpNU0V3SHdZRFZRUUREQmhyTTNNdFkyeHAKWlc1MExXTmhRREUyT0RJeE9USTBNREV3SGhjTk1qTXdOREl5TVRrME1EQXhXaGNOTXpNd05ERTVNVGswTURBeApXakFqTVNFd0h3WURWUVFEREJock0zTXRZMnhwWlc1MExXTmhRREUyT0RJeE9USTBNREV3V1RBVEJnY3Foa2pPClBRSUJCZ2dxaGtqT1BRTUJCd05DQUFTeTlwUFVGampadDBjRXhLLzFseTk0ODB2aWRQUEx4UjFaOGpWcHNvalMKZE93T2hBbnVqVlVDUmtjQ3BNQkJKV3U3Tmp4L3RWMzlJdndQQ2NzMzc0aTVvMEl3UURBT0JnTlZIUThCQWY4RQpCQU1DQXFRd0R3WURWUjBUQVFIL0JBVXdBd0VCL3pBZEJnTlZIUTRFRmdRVTlWVkY3aW4zdkxvSG0rL3BrY0x0CkF5cy83TnN3Q2dZSUtvWkl6ajBFQXdJRFJ3QXdSQUlnSWYydnFaSkg1dXlkQitoSlhYOFhzR2RqTkZZeWZnL2sKOFJnNHJKYk9EOTRDSUVNY0kwVVVmUUtLRURPR3UreXRLOHppa0RBMS9rNTZFY0wzRjF4czhKVXIKLS0tLS1FTkQgQ0VSVElGSUNBVEUtLS0tLQo=
          client-key-data: LS0tLS1CRUdJTiBFQyBQUklWQVRFIEtFWS0tLS0tCk1IY0NBUUVFSU9IalBWMmdBRGNCdlpvaktyd2ZMeXBsRTVkUmZSbThEWGxmL0lZTmtOWlRvQW9HQ0NxR1NNNDkKQXdFSG9VUURRZ0FFcGhFMVczZENyRFpSNThSR1dNSUNhNXJXQk85cmRSbXZWVm9CV2EzYWV0dVhMOThNa3JtRAp6TUxqa0dubVdQelVJVlBTMm1Rc2dTL1o4Ym9Lbldqbk93PT0KLS0tLS1FTkQgRUMgUFJJVkFURSBLRVktLS0tLQo=
    '';    
  };

}
