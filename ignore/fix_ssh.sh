{
echo -n 'Ciphers '
ssh -Q cipher | tr '\n' ',' | sed -e 's/,$//'; echo

echo -n 'MACs '
ssh -Q mac | tr '\n' ',' | sed -e 's/,$//'; echo

echo -n 'HostKeyAlgorithms '
ssh -Q key | tr '\n' ',' | sed -e 's/,$//'; echo

echo -n 'KexAlgorithms '
ssh -Q kex | tr '\n' ',' | sed -e 's/,$//'; echo

} >> ~/.ssh/config