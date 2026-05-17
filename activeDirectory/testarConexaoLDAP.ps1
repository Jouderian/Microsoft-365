<#
  .SYNOPSIS
    Testar a conexão LDAP com um servidor Active Directory
  .DESCRIPTION
    Testa a conexão e autenticação LDAP/LDAPS com um servidor do Active Directory. O script valida a conectividade de rede nas portas LDAP padrão (389) e segura (636) e tenta autenticar as credenciais informadas pelo usuário de forma interativa.
  .AUTHOR
    Vanderson Hay
  .CREATED
    27/06/25
  .VERSION
    02 (01/07/25) - Jouderian Nobre: Melhoria para solicitar as informações do usuário e tratar erros
  .OUTPUT
    Informa se foi possível conectar ao servidor LDAP e autenticar o usuário com sucesso.
#>

Clear-Host

# Solicita as informações ao usuário
$servidor = Read-Host "Informe o nome do dominio (exemplo: jalix.srv):"
$username = Read-Host "Informe o usuário (exemplo: jnobre):"
$password = Read-Host "Informe a senha:" -AsSecureString

# Converte a senha segura para texto simples para uso no DirectoryEntry
$ptr = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($password)
$passwordPlain = [System.Runtime.InteropServices.Marshal]::PtrToStringBSTR($ptr)

$ldapServer = "LDAP://$($servidor)"
$directoryEntry = New-Object System.DirectoryServices.DirectoryEntry($ldapServer, $username, $passwordPlain)

# Testa portas LDAP padrão e segura
$porta389 = Test-NetConnection -ComputerName $servidor -Port 389
$porta636 = Test-NetConnection -ComputerName $servidor -Port 636

if (-not $porta389.TcpTestSucceeded -and -not $porta636.TcpTestSucceeded){
  Write-Host "Não foi possível conectar às portas LDAP (389 ou 636) do servidor $servidor." -ForegroundColor Red
  exit 1
}

try {
  $null = $directoryEntry.NativeObject
  if ($directoryEntry.Name){
    Write-Host "Autenticação LDAP bem-sucedida para o usuário $username no servidor $servidor." -ForegroundColor Green
  } else {
    Write-Host "Conexão estabelecida, mas NÃO foi possível autenticar o usuário. Verifique as credenciais." -ForegroundColor Red
  }
} catch {
  Write-Host "Falha na autenticação LDAP: $($_.Exception.Message)" -ForegroundColor Red
}