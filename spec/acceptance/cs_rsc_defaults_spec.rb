# frozen_string_literal: true

require 'spec_helper_acceptance'

describe 'corosync' do
  if fact('os.family') == 'Debian'
    cert = '-----BEGIN CERTIFICATE-----
MIIDVzCCAj+gAwIBAgIJAJNCo5ZPmKegMA0GCSqGSIb3DQEBBQUAMEIxCzAJBgNV
BAYTAlhYMRUwEwYDVQQHDAxEZWZhdWx0IENpdHkxHDAaBgNVBAoME0RlZmF1bHQg
Q29tcGFueSBMdGQwHhcNMTUwMjI2MjI1MjU5WhcNMTUwMzI4MjI1MjU5WjBCMQsw
CQYDVQQGEwJYWDEVMBMGA1UEBwwMRGVmYXVsdCBDaXR5MRwwGgYDVQQKDBNEZWZh
dWx0IENvbXBhbnkgTHRkMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA
uCPPbDgErGUVs1pKqv59OatjCEU4P9QcmhDYFR7RBN8m08mIqd+RTuiHUKj6C9Rk
vWQ5bYrGQo/+4E0ziAUuUzzITlpIYLVltca6eBhKUqO3Cd0NMRVc2k4nx5948nwv
9FVOIfOOY6BN2ALglfBfLnhObbzJjs6OSZ7bUCpXVPV01t/61Jj3jQ3+R8b7AaoR
mw7j0uWaFimKt/uag1qqKGw3ilieMhHlG0Da5x9WLi+5VIM0t1rcpR58LLXVvXZB
CrQBucm2xhZsz7R76Ai+NL8zhhyzCZidZ2NtJ3E1wzppcSDAfNrru+rcFSlZ4YG+
lMCqZ1aqKWVXmb8+Vg7IkQIDAQABo1AwTjAdBgNVHQ4EFgQULxI68KhZwEF5Q9al
xZmFDR+Beu4wHwYDVR0jBBgwFoAULxI68KhZwEF5Q9alxZmFDR+Beu4wDAYDVR0T
BAUwAwEB/zANBgkqhkiG9w0BAQUFAAOCAQEAsa0YKPixD6VmDo3pal2qqichHbdT
hUONk2ozzRoaibVocqKx2T6Ho23wb/lDlRUu4K4DMO663uumzI9lNoOewa0MuW1D
J52cejAMVsP3ROOdxBv0HZIVVJ8NLBHNLFOHJEDtvzogLVplzmo59vPAdmQo6eIV
japvs+0tdy9iwHj3z1ZME2Ntm/5TzG537e7Hb2zogatM9aBTUAWlZ1tpoaXuTH52
J76GtqoIOh+CTeY/BMwBotdQdgeR0zvjE9FuLWkhTmRtVFhbVIzJbFlFuYq5d3LH
NWyN0RsTXFaqowV1/HSyvfD7LoF/CrmN5gOAM3Ierv/Ti9uqGVhdGBd/kw=='
    File.write('/tmp/ca.pem', cert)
    it 'creates a rsc_defaults' do
      pp = <<-EOS
        file { '/tmp/ca.pem':
          ensure  => file,
          content => '#{cert}'
        } ->
        class { 'corosync':
          multicast_address => '224.0.0.1',
          authkey           => '/tmp/ca.pem',
          bind_address      => '127.0.0.1',
          set_votequorum    => true,
          quorum_members    => ['127.0.0.1'],
        }
        cs_rsc_defaults { 'resource-stickiness':
           value => '98898'
        }
      EOS

      apply_manifest(pp, catch_failures: true, debug: false, trace: true)
      apply_manifest(pp, catch_changes: true, debug: false, trace: true)

      shell('cibadmin --query') do |r|
        expect(r.stdout).to match(%r{resource-stickiness.*98898})
      end
    end

    it 'removes the rsc_default' do
      pp = <<-EOS
        cs_rsc_defaults { 'resource-stickiness':
          ensure => absent
          }
      EOS
      apply_manifest(pp, expect_changes: true, debug: false, trace: true)
      apply_manifest(pp, catch_changes: true, debug: false, trace: true)

      shell('cibadmin --query') do |r|
        expect(r.stdout).not_to match(%r{resource-stickiness.*98898})
      end
    end
  end
end
