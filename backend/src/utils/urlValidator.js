const dns = require('dns').promises;
const net = require('net');

/**
 * Returns true if an IPv4 address falls within a private/loopback/link-local
 * range that should never be reachable from the public internet.
 */
function isPrivateIp(ip) {
  // Loopback
  if (ip === '127.0.0.1' || ip.startsWith('127.')) return true;
  // Link-local (AWS metadata, Azure IMDS, GCP metadata)
  if (ip.startsWith('169.254.')) return true;
  // RFC-1918 private ranges
  if (ip.startsWith('10.')) return true;
  if (ip.startsWith('192.168.')) return true;
  // 172.16.0.0/12
  const parts = ip.split('.').map(Number);
  if (parts[0] === 172 && parts[1] >= 16 && parts[1] <= 31) return true;
  // IPv6 loopback mapped in IPv4
  if (ip === '::1' || ip === '0:0:0:0:0:0:0:1') return true;
  // Unspecified / broadcast
  if (ip === '0.0.0.0' || ip === '255.255.255.255') return true;
  return false;
}

/**
 * Validates that a URL is a safe, public HTTP/HTTPS target.
 * Resolves the hostname via DNS and checks all returned IPs.
 *
 * @param {string} rawUrl
 * @throws {Error} with a user-safe message if the URL is unsafe
 */
async function validatePublicUrl(rawUrl) {
  let parsed;
  try {
    parsed = new URL(rawUrl);
  } catch {
    throw new Error('Invalid URL format. Please provide a full URL including http:// or https://');
  }

  if (parsed.protocol !== 'http:' && parsed.protocol !== 'https:') {
    throw new Error('Only http:// and https:// URLs are allowed.');
  }

  const hostname = parsed.hostname;

  // Block raw IP addresses that are private
  if (net.isIP(hostname)) {
    if (isPrivateIp(hostname)) {
      throw new Error('URL must point to a public internet address, not a private or loopback IP.');
    }
    return; // Public raw IP — allow
  }

  // Resolve hostname and check all resolved IPs
  let addresses;
  try {
    const result = await dns.lookup(hostname, { all: true });
    addresses = result.map((r) => r.address);
  } catch {
    throw new Error(`Could not resolve hostname: ${hostname}. Is the URL correct?`);
  }

  for (const addr of addresses) {
    if (isPrivateIp(addr)) {
      throw new Error(
        `URL hostname "${hostname}" resolves to a private IP address (${addr}). ` +
        'Only public internet URLs are allowed.'
      );
    }
  }
}

module.exports = { validatePublicUrl };
