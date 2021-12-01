task subset_vcf {
	File vcffile
	File? bedfile
	File? samplefile
    File? variantfile
	Float? min_maf
	Int? memory
	Int? disk
	String outfile = sub(basename(vcffile), ".vcf.gz$", "_subset.vcf.gz")
	command {
		bcftools view ${"-i 'ID=@" + variantfile +"'"} -Oz ${"-R " + bedfile} ${"-S " + samplefile} ${"--min-af " + min_maf + ":minor"} ${vcffile} > ${outfile}
	}
	runtime {
		docker: "biocontainers/bcftools:v1.9-1-deb_cv1"
		disks: "local-disk " + select_first([disk,"100"]) + " HDD"
		memory: select_first([memory,"30"]) + " GB"
	}
	output {
		File subsetfile = "${outfile}"
	}
}
workflow subset_vcf_wf {
	# inputs
	Array[File] vcffiles
	File? bedfile
	File? samplefile
    File? variantfile
	Float? min_maf
	Int? memory
	Int? disk
	# Workflow metadata
	meta {
		description: "This workflow subsets a VCF file by genomic position and sample id."
		tags: "genetics"
	    author: "Tim Majarian, Kenny Westerman"
	    email: "kewesterman@mgh.harvard.edu"
	}
	# Parameter metadata
	parameter_meta {
		vcffiles: "An array of files in VCF format."
		bedfile: "Genomic coordinates in BED format to be included in the output dataset. Only the first 3 columns are used (chr, start, end) and positions are 0-based. Ensure that your chromosome encoding matches that of the VCF files (chr1 != 1)"
		samplefile: "A file containing 1 sample id per line to be included in the output dataset. Sample ids must be present in the VCF files."
        variantfile: "A file with variant list."
		min_maf: "minimum minor allele frequency to retain"
		memory: "memory in GB to allocate per VCF file (default: 30 GB)"
		disk: "disk space in GB to allocate per VCF file (default: 100 GB)"
	}
	scatter(vcffile in vcffiles) {
		call subset_vcf {
			input:
				vcffile = vcffile,
				bedfile = bedfile,
				samplefile = samplefile,
                variantfile = variantfile,
				min_maf = min_maf,
				memory = memory,
				disk = disk
		}
	}
	output {
		Array[File] subsetfiles = subset_vcf.subsetfile
    }
}
