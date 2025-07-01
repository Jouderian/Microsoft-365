#--------------------------------------------------------------------------------------------------------
# Autor: Vanderson Hay
# Descricao: Testar a conexão LDAP com um servidor Active Directory
# Versao: 1 (27/06/25) Vanderson Hay
# Versao: 2 (01/07/25) Jouderian Nobre: Melhoria para solicitar as informações do usuário e tratar erros
#--------------------------------------------------------------------------------------------------------

Clear-Host

# Solicita as informações ao usuário
$servidor = Read-Host "Informe o nome do dominio:"
$username = Read-Host "Informe o usuário:"
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