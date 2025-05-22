
fasta = Dir["*.fasta"]

puts "sample\tassembly"

fasta.each do |f|
	
	fa = f.split("/")[0]
	s = fa.split(".fasta")[0]
	s_full = "https://raw.githubusercontent.com/marchoeppner/spread/refs/heads/main/assets/test/#{fa}"
	puts "#{s}\t#{s_full}"

end
