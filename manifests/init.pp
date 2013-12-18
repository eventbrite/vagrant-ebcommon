class dev {
  notify { 'Development provision!':}
  notify { "Github full name: ${github_full_name}":}
  notify { "Github email: ${github_email}":}
}

include dev
