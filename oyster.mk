#!/usr/bin/make -rRsf

SHELL=/bin/bash -o pipefail

#USAGE:
#
#	oyster.mk main READ1= READ2= MEM=500 CPU=24 RUNOUT=runname
# oyster.mk orthofuse FASTADIR= READ1= READ2= MEM=500 CPU=24 RUNOUT=runname
#

VERSION = 2.0.0
MAKEDIR := $(dir $(firstword $(MAKEFILE_LIST)))
DIR := ${CURDIR}
CPU=16
MEM=128
RCORR := ${shell which rcorrector}
RCORRDIR := $(dir $(firstword $(RCORR)))
READ1=
READ2=
BUSCO := ${shell which run_BUSCO.py}
BUSCODIR := $(dir $(firstword $(BUSCO)))
RUNOUT =
ASSEMBLY=
LINEAGE=
BUSCOUT := BUSCO_$(shell basename ${ASSEMBLY} .fasta)
BUSCODB :=
START=1
INPUT := $(shell basename ${READ1})
FASTADIR=
brewpath := $(shell which brew 2>/dev/null)
rcorrpath := $(shell which rcorrector 2>/dev/null)
trimmomaticpath := $(shell which trimmomatic 2>/dev/null)
trinitypath := $(shell which Trinity 2>/dev/null)
spadespath := $(shell which rnaspades.py 2>/dev/null)
salmonpath := $(shell which salmon 2>/dev/null)
mclpath := $(shell which mcl 2>/dev/null)
buscopath := $(shell which run_BUSCO.py 2>/dev/null)
seqtkpath := $(shell which seqtk 2>/dev/null)
transratepath := $(shell which transrate 2>/dev/null)
transabyss := $(shell which transabyss 2>/dev/null)
BUSCO_CONFIG_FILE := ${MAKEDIR}/software/config.ini
export BUSCO_CONFIG_FILE

run_trimmomatic:
run_rcorrector:${DIR}/rcorr/${RUNOUT}.TRIM_1P.cor.fq
run_trinity:${DIR}/assemblies/${RUNOUT}.trinity.Trinity.fasta
run_spades55:${DIR}/assemblies/${RUNOUT}.spades55.fasta
run_spades75:${DIR}/assemblies/${RUNOUT}.spades75.fasta
run_transabyss:${DIR}/assemblies/${RUNOUT}.transabyss.fasta
merge:${DIR}/orthofuse/${RUNOUT}/merged.fasta
orthotransrate:${DIR}/orthofuse/${RUNOUT}/orthotransrate.done
orthofusing:${DIR}/assemblies/${RUNOUT}.orthomerged.fasta
salmon:${DIR}/quants/salmon_orthomerged_${RUNOUT}/quant.sf
diamond:${DIR}/assemblies/diamond/${RUNOUT}.trinity.diamond.txt
posthack:${DIR}/assemblies/diamond/${RUNOUT}.newbies.fasta
main: setup check welcome run_trimmomatic run_rcorrector run_trinity run_spades75 run_spades55 run_transabyss merge orthotransrate orthofusing diamond posthack cdhit salmon busco transrate report
orthofuse:merge orthotransrate orthofusing
report:busco transrate reportgen
busco:${DIR}/reports/${RUNOUT}.busco.done
transrate:${DIR}/reports/${RUNOUT}.transrate.done
clean:
setup:${DIR}/setup.done
cdhit:${DIR}/assemblies/${RUNOUT}.ORP.fasta

.DELETE_ON_ERROR:
.PHONY:report check clean

${DIR}/setup.done:
	@mkdir -p ${DIR}/reads
	@mkdir -p ${DIR}/assemblies
	@mkdir -p ${DIR}/rcorr
	@mkdir -p ${DIR}/reports
	@mkdir -p ${DIR}/orthofuse
	@mkdir -p ${DIR}/quants
	@mkdir -p ${DIR}/assemblies/diamond
	touch ${DIR}/setup.done

check:
ifdef salmonpath
else
	$(error "\n\n*** SALMON is not installed, must fix ***")
endif
ifdef transratepath
else
	$(error "\n\n*** TRANSRATE is not installed, must fix ***")
endif
ifdef seqtkpath
else
	$(error "\n\n*** SEQTK is not installed, must fix ***")
endif
ifdef buscopath
else
	$(error "\n\n*** BUSCO is not installed, must fix ***")
endif
ifdef mclpath
else
	$(error "\n\n*** MCL is not installed, must fix ***")
endif
ifdef spadespath
else
	$(error "\n\n*** SPADES is not installed, must fix ***")
endif
ifdef trinitypath
else
	$(error "\n\n*** TRINITY is not installed, must fix ***")
endif
ifdef trimmomaticpath
else
	$(error  "\n\n Maybe TRIMMOMATIC is not installed, or maybe you are working on Bridges")
endif
ifdef transabyss
else
	$(error "\n\n *** transabyss is not installed, must fix ***")
endif
ifdef rcorrpath
else
	$(error "\n\n *** RCORRECTOR is not installed, must fix ***")
endif
ifeq ($(shell zsh --version | awk '{print $$2}'),5.0.2)
	$(error "\n\n *** TRANSABySS Requires at least ZSH 5.0.8, you have 5.0.2 and must upgrade ***")
endif
ifeq ($(shell zsh --version | awk '{print $2}'),5.0.5)
	$(error "\n\n *** TRANSABySS Requires at least ZSH 5.0.8, you have 5.0.5 and must upgrade ***")
endif
ifeq ($(shell zsh --version | awk '{print $$2}'),5.0.6)
	$(error "\n\n *** TRANSABySS Requires at least ZSH 5.0.8, you have 5.0.6 and must upgrade ***")
endif
ifeq ($(shell zsh --version | awk '{print $$2}'),5.0.7)
	$(error "\n\n *** TRANSABySS Requires at least ZSH 5.0.8, you have 5.0.7 and must upgrade ***")
endif

welcome:
	printf "\n\n*****  Welcome to the Oyster River ***** \n"
	printf "*****  This is version ${VERSION} ***** \n\n "
	printf " \n\n"

${DIR}/rcorr/${RUNOUT}.TRIM_1P.fastq:
	@if [ $$(hostname | cut -d. -f3-5) == 'bridges.psc.edu' ];\
	then\
		java -jar $$TRIMMOMATIC_HOME/trimmomatic-0.36.jar PE -threads $(CPU) -baseout ${DIR}/rcorr/${RUNOUT}.TRIM.fastq ${READ1} ${READ2} LEADING:3 TRAILING:3 ILLUMINACLIP:${MAKEDIR}/barcodes/barcodes.fa:2:30:10 MINLEN:25;\
	else\
		trimmomatic PE -threads $(CPU) -baseout ${DIR}/rcorr/${RUNOUT}.TRIM.fastq ${READ1} ${READ2} LEADING:3 TRAILING:3 ILLUMINACLIP:${MAKEDIR}/barcodes/barcodes.fa:2:30:10 MINLEN:25;\
	fi

${DIR}/rcorr/${RUNOUT}.TRIM_1P.cor.fq:${DIR}/rcorr/${RUNOUT}.TRIM_1P.fastq
	perl ${RCORRDIR}/run_rcorrector.pl -t $(CPU) -k 31 -1 ${DIR}/rcorr/${RUNOUT}.TRIM_1P.fastq -2 ${DIR}/rcorr/${RUNOUT}.TRIM_2P.fastq -od ${DIR}/rcorr

${DIR}/assemblies/${RUNOUT}.trinity.Trinity.fasta:${DIR}/rcorr/${RUNOUT}.TRIM_1P.cor.fq
	Trinity --no_version_check --bypass_java_version_check --no_normalize_reads --seqType fq --output ${DIR}/assemblies/${RUNOUT}.trinity --max_memory $(MEM)G --left ${DIR}/rcorr/${RUNOUT}.TRIM_1P.cor.fq --right ${DIR}/rcorr/${RUNOUT}.TRIM_2P.cor.fq --CPU $(CPU) --inchworm_cpu 10 --full_cleanup
	awk '{print $$1}' ${DIR}/assemblies/${RUNOUT}.trinity.Trinity.fasta > ${DIR}/assemblies/${RUNOUT}.trinity.Trinity.fa && mv -f ${DIR}/assemblies/${RUNOUT}.trinity.Trinity.fa ${DIR}/assemblies/${RUNOUT}.trinity.Trinity.fasta

${DIR}/assemblies/${RUNOUT}.spades55.fasta:${DIR}/rcorr/${RUNOUT}.TRIM_1P.cor.fq
	rnaspades.py --only-assembler -o ${DIR}/assemblies/${RUNOUT}.spades_k55 --threads $(CPU) --memory $(MEM) -k 55 -1 ${DIR}/rcorr/${RUNOUT}.TRIM_1P.cor.fq -2 ${DIR}/rcorr/${RUNOUT}.TRIM_2P.cor.fq
	mv ${DIR}/assemblies/${RUNOUT}.spades_k55/transcripts.fasta ${DIR}/assemblies/${RUNOUT}.spades55.fasta
	rm -fr ${DIR}/assemblies/${RUNOUT}.spades_k55

${DIR}/assemblies/${RUNOUT}.spades75.fasta:${DIR}/rcorr/${RUNOUT}.TRIM_1P.cor.fq
	rnaspades.py --only-assembler -o ${DIR}/assemblies/${RUNOUT}.spades_k75 --threads $(CPU) --memory $(MEM) -k 75 -1 ${DIR}/rcorr/${RUNOUT}.TRIM_1P.cor.fq -2 ${DIR}/rcorr/${RUNOUT}.TRIM_2P.cor.fq
	mv ${DIR}/assemblies/${RUNOUT}.spades_k75/transcripts.fasta ${DIR}/assemblies/${RUNOUT}.spades75.fasta
	rm -fr ${DIR}/assemblies/${RUNOUT}.spades_k75

${DIR}/assemblies/${RUNOUT}.transabyss.fasta:${DIR}/rcorr/${RUNOUT}.TRIM_1P.cor.fq
	transabyss --threads $(CPU) --outdir ${DIR}/assemblies/${RUNOUT}.transabyss --kmer 32 --length 250 --name ${RUNOUT}.transabyss.fasta --pe ${DIR}/rcorr/${RUNOUT}.TRIM_1P.cor.fq ${DIR}/rcorr/${RUNOUT}.TRIM_2P.cor.fq
	awk '{print $$1}' ${DIR}/assemblies/${RUNOUT}.transabyss/${RUNOUT}.transabyss.fasta-final.fa >  ${DIR}/assemblies/${RUNOUT}.transabyss.fasta
	rm -fr ${DIR}/assemblies/${RUNOUT}.transabyss/ ${DIR}/assemblies/${RUNOUT}.transabyss/${RUNOUT}.transabyss.fasta-final.fa

${DIR}/orthofuse/${RUNOUT}/merged.fasta:
	mkdir -p ${DIR}/orthofuse/${RUNOUT}/working
	for fasta in $$(ls ${DIR}/assemblies/${RUNOUT}*fasta); do python ${MAKEDIR}/scripts/long.seq.py ${DIR}/assemblies/$$(basename $$fasta) ${DIR}/orthofuse/${RUNOUT}/working/$$(basename $$fasta).short.fasta 200; done
	( \
	source ${MAKEDIR}/software/anaconda/install/bin/activate py27; \
	python $$(which orthofuser.py) -I 4 -f ${DIR}/orthofuse/${RUNOUT}/working/ -og -t $(CPU) -a $(CPU); \
	source ${MAKEDIR}/software/anaconda/install/bin/activate orp_v2;\
	)
	cat ${DIR}/orthofuse/${RUNOUT}/working/*short.fasta > ${DIR}/orthofuse/${RUNOUT}/merged.fasta

${DIR}/orthofuse/${RUNOUT}/orthotransrate.done:${DIR}/orthofuse/${RUNOUT}/merged.fasta
	export END=$$(wc -l $$(find ${DIR}/orthofuse/${RUNOUT}/working/ -name Orthogroups.txt 2> /dev/null) | awk '{print $$1}') && \
	export ORTHOINPUT=$$(find ${DIR}/orthofuse/${RUNOUT}/working/ -name Orthogroups.txt 2> /dev/null) && \
	echo $$(eval echo "{1..$$END}") | tr ' ' '\n' > ${DIR}/orthofuse/${RUNOUT}/${RUNOUT}.list && \
	cat ${DIR}/orthofuse/${RUNOUT}/${RUNOUT}.list | parallel  -j $(CPU) -k "sed -n ''{}'p' $$ORTHOINPUT | tr ' ' '\n' | sed '1d' > ${DIR}/orthofuse/${RUNOUT}/{1}.groups"
	${MAKEDIR}/software/orp-transrate/transrate -o ${DIR}/orthofuse/${RUNOUT}/merged -t $(CPU) -a ${DIR}/orthofuse/${RUNOUT}/merged.fasta --left ${READ1} --right ${READ2}
	touch ${DIR}/orthofuse/${RUNOUT}/orthotransrate.done

${DIR}/assemblies/${RUNOUT}.orthomerged.fasta:${DIR}/orthofuse/${RUNOUT}/orthotransrate.done
	echo All the text files are made, start GREP
	find ${DIR}/orthofuse/${RUNOUT}/ -name '*groups' 2> /dev/null | parallel -j $(CPU) "grep -Fwf {} $$(find ${DIR}/orthofuse/${RUNOUT}/ -name contigs.csv 2> /dev/null) > {1}.orthout 2> /dev/null"
	echo About to delete all the text files
	find ${DIR}/orthofuse/${RUNOUT}/ -name '*groups' -delete
	echo Search output files
	find ${DIR}/orthofuse/${RUNOUT}/ -name '*orthout' 2> /dev/null | parallel -j $(CPU) "awk -F, -v max=0 '{if(\$$14>max){want=\$$1; max=\$$14}}END{print want}'" >> ${DIR}/orthofuse/${RUNOUT}/good.${RUNOUT}.list
	find ${DIR}/orthofuse/${RUNOUT}/ -name '*orthout' -delete
	python ${MAKEDIR}/scripts/filter.py ${DIR}/orthofuse/${RUNOUT}/merged.fasta ${DIR}/orthofuse/${RUNOUT}/good.${RUNOUT}.list > ${DIR}/orthofuse/${RUNOUT}/${RUNOUT}.orthomerged.fasta
	cp ${DIR}/orthofuse/${RUNOUT}/${RUNOUT}.orthomerged.fasta ${DIR}/assemblies/${RUNOUT}.orthomerged.fasta
	rm ${DIR}/orthofuse/${RUNOUT}/good.${RUNOUT}.list

${DIR}/assemblies/diamond/${RUNOUT}.trinity.diamond.txt: ${DIR}/assemblies/${RUNOUT}.transabyss.fasta ${DIR}/assemblies/${RUNOUT}.spades75.fasta ${DIR}/assemblies/${RUNOUT}.spades55.fasta ${DIR}/assemblies/${RUNOUT}.trinity.Trinity.fasta
	diamond blastx -p $(CPU) -e 1e-8 --top 0.1 -q ${DIR}/assemblies/${RUNOUT}.orthomerged.fasta -d ${MAKEDIR}/software/diamond/swissprot -o ${DIR}/assemblies/diamond/${RUNOUT}.orthomerged.diamond.txt
	diamond blastx -p $(CPU) -e 1e-8 --top 0.1 -q ${DIR}/assemblies/${RUNOUT}.transabyss.fasta -d ${MAKEDIR}/software/diamond/swissprot -o ${DIR}/assemblies/diamond/${RUNOUT}.transabyss.diamond.txt
	diamond blastx -p $(CPU) -e 1e-8 --top 0.1 -q ${DIR}/assemblies/${RUNOUT}.spades75.fasta -d ${MAKEDIR}/software/diamond/swissprot  -o ${DIR}/assemblies/diamond/${RUNOUT}.spades75.diamond.txt
	diamond blastx -p $(CPU) -e 1e-8 --top 0.1 -q ${DIR}/assemblies/${RUNOUT}.spades55.fasta -d ${MAKEDIR}/software/diamond/swissprot -o ${DIR}/assemblies/diamond/${RUNOUT}.spades55.diamond.txt
	diamond blastx -p $(CPU) -e 1e-8 --top 0.1 -q ${DIR}/assemblies/${RUNOUT}.trinity.Trinity.fasta -d ${MAKEDIR}/software/diamond/swissprot  -o ${DIR}/assemblies/diamond/${RUNOUT}.trinity.diamond.txt
	awk '{print $$2}' ${DIR}/assemblies/diamond/${RUNOUT}.trinity.diamond.txt | awk -F "|" '{print $$3}' | cut -d _ -f2 | sort | uniq | wc -l > ${DIR}/assemblies/diamond/${RUNOUT}.unique.trinity.txt
	awk '{print $$2}' ${DIR}/assemblies/diamond/${RUNOUT}.spades75.diamond.txt | awk -F "|" '{print $$3}' | cut -d _ -f2 | sort | uniq | wc -l > ${DIR}/assemblies/diamond/${RUNOUT}.unique.sp75.txt
	awk '{print $$2}' ${DIR}/assemblies/diamond/${RUNOUT}.spades55.diamond.txt | awk -F "|" '{print $$3}' | cut -d _ -f2 | sort | uniq | wc -l > ${DIR}/assemblies/diamond/${RUNOUT}.unique.sp55.txt
	awk '{print $$2}' ${DIR}/assemblies/diamond/${RUNOUT}.transabyss.diamond.txt | awk -F "|" '{print $$3}' | cut -d _ -f2 | sort | uniq | wc -l > ${DIR}/assemblies/diamond/${RUNOUT}.unique.transabyss.txt



#list1 is unique geneIDs in orthomerged
#list2 is unique  geneIDs in other assemblies
#list3 is which genes are in other assemblies but not in orthomerged
#list4 are the contig IDs from {sp55,sp75,trin,ta} from list3
#list5 is unique IDs contig IDs from list4
#list6 is contig IDs from orthomerged FASTAs
#list7 is stuff that is in 5 but not 6

${DIR}/assemblies/diamond/${RUNOUT}.newbies.fasta:${DIR}/assemblies/diamond/${RUNOUT}.trinity.diamond.txt
	cd ${DIR}/assemblies/diamond/ && cut -f2 ${RUNOUT}.orthomerged.diamond.txt | cut -d "|" -f3 | cut -d "_" -f1 | sort --parallel=20 |uniq > ${RUNOUT}.list1
	cd ${DIR}/assemblies/diamond/ && cut -f2 ${RUNOUT}.{transabyss,spades75,spades55,trinity}.diamond.txt | cut -d "|" -f3 | cut -d "_" -f1 | sort --parallel=20 |uniq > ${RUNOUT}.list2
	cd ${DIR}/assemblies/diamond/ && grep -xFvwf ${RUNOUT}.list1 ${RUNOUT}.list2 > ${RUNOUT}.list3
	cd ${DIR}/assemblies/diamond/ && for item in $$(cat ${RUNOUT}.list3); do grep -F $$item ${RUNOUT}.{transabyss,spades75,spades55,trinity}.diamond.txt | head -1 | cut -f1; done | cut -d ":" -f2 | sort | uniq >> ${RUNOUT}.list5
	cd ${DIR}/assemblies/diamond/ && grep -F ">" ${DIR}/assemblies/${RUNOUT}.orthomerged.fasta | sed 's_>__' > ${RUNOUT}.list6
	cd ${DIR}/assemblies/diamond/ && grep -xFvwf ${RUNOUT}.list6 ${RUNOUT}.list5 > ${RUNOUT}.list7
	cd ${DIR}/assemblies/diamond/ && python ${MAKEDIR}/scripts/filter.py <(cat ../${RUNOUT}.{spades55,spades75,transabyss,trinity.Trinity}.fasta) ${RUNOUT}.list7 >> ${RUNOUT}.newbies.fasta
	cd ${DIR}/assemblies/diamond/ &&  cat ${RUNOUT}.newbies.fasta ${DIR}/assemblies/${RUNOUT}.orthomerged.fasta > tmp.fasta && mv tmp.fasta ${DIR}/assemblies/${RUNOUT}.orthomerged.fasta
	cd ${DIR}/assemblies/diamond/ && rm -f ${RUNOUT}.list*

${DIR}/assemblies/${RUNOUT}.ORP.fasta:${DIR}/assemblies/${RUNOUT}.orthomerged.fasta
	cd ${DIR}/assemblies/ && cd-hit-est -M 5000 -T $(CPU) -c .98 -i ${DIR}/assemblies/${RUNOUT}.orthomerged.fasta -o ${DIR}/assemblies/${RUNOUT}.ORP.fasta
	diamond blastx -p $(CPU) -e 1e-8 --top 0.1 -q ${DIR}/assemblies/${RUNOUT}.ORP.fasta -d ${MAKEDIR}/software/diamond/swissprot  -o ${DIR}/assemblies/${RUNOUT}.ORP.diamond.txt
	awk '{print $$2}' ${DIR}/assemblies/${RUNOUT}.ORP.diamond.txt | awk -F "|" '{print $$3}' | cut -d _ -f2 | sort | uniq | wc -l > ${DIR}/assemblies/${RUNOUT}.unique.ORP.txt
	rm ${DIR}/assemblies/${RUNOUT}.ORP.fasta.clstr

${DIR}/reports/${RUNOUT}.busco.done:${DIR}/assemblies/${RUNOUT}.ORP.fasta
	export BUSCO_CONFIG_FILE=${MAKEDIR}/software/config.ini
	python $$(which run_BUSCO.py) -i ${DIR}/assemblies/${RUNOUT}.ORP.fasta -m transcriptome --cpu $(CPU) -o ${RUNOUT}.orthomerged
	mv run_${RUNOUT}* ${DIR}/reports/
	touch ${DIR}/reports/${RUNOUT}.busco.done

${DIR}/reports/${RUNOUT}.transrate.done:${DIR}/assemblies/${RUNOUT}.ORP.fasta
	${MAKEDIR}/software/orp-transrate/transrate -o ${DIR}/reports/transrate_${RUNOUT}  -a ${DIR}/assemblies/${RUNOUT}.ORP.fasta --left ${DIR}/rcorr/${RUNOUT}.TRIM_1P.cor.fq --right ${DIR}/rcorr/${RUNOUT}.TRIM_2P.cor.fq -t $(CPU)
	touch ${DIR}/reports/${RUNOUT}.transrate.done

${DIR}/quants/salmon_orthomerged_${RUNOUT}/quant.sf:${DIR}/assemblies/${RUNOUT}.ORP.fasta
	salmon index --no-version-check -t ${DIR}/assemblies/${RUNOUT}.ORP.fasta  -i ${RUNOUT}.ortho.idx --type quasi -k 31
	salmon quant --no-version-check -p $(CPU) -i ${RUNOUT}.ortho.idx --seqBias --gcBias -l a -1 ${DIR}/rcorr/${RUNOUT}.TRIM_1P.cor.fq -2 ${DIR}/rcorr/${RUNOUT}.TRIM_2P.cor.fq -o ${DIR}/quants/salmon_orthomerged_${RUNOUT}
	rm -fr ${RUNOUT}.ortho.idx

clean:
	rm -fr ${DIR}/orthofuse/${RUNOUT}/ ${DIR}/rcorr/${RUNOUT}.TRIM_2P.fastq ${DIR}/rcorr/${RUNOUT}.TRIM_1P.fastq ${DIR}/rcorr/${RUNOUT}.TRIM_1P.cor.fq ${DIR}/assemblies/${RUNOUT}.trinity.Trinity.fasta \
	${DIR}/assemblies/${RUNOUT}.spades55.fasta ${DIR}/assemblies/${RUNOUT}.spades75.fasta ${DIR}/assemblies/${RUNOUT}.transabyss.fasta \
	${DIR}/orthofuse/${RUNOUT}/merged.fasta ${DIR}/assemblies/${RUNOUT}.orthomerged.fasta ${DIR}/assemblies/diamond/${RUNOUT}.trinity.diamond.txt \
	${DIR}/assemblies/diamond/${RUNOUT}.newbies.fasta ${DIR}/reports/busco.done ${DIR}/reports/transrate.done ${DIR}/quants/salmon_orthomerged_${RUNOUT}/quant.sf \
	${DIR}/rcorr/${RUNOUT}.TRIM_2P.cor.fq ${DIR}/reports/run_${RUNOUT}.orthomerged/ ${DIR}/reports/transrate_${RUNOUT}/

reportgen:
	printf "\n\n*****  QUALITY REPORT FOR: ${RUNOUT} using the ORP version ${VERSION} ****"
	printf "\n*****  THE ASSEMBLY CAN BE FOUND HERE: ${DIR}/assemblies/${RUNOUT}.ORP.fasta **** \n\n"
	printf "*****  BUSCO SCORE ~~~~~>           " | tee -a ${DIR}/reports/qualreport.${RUNOUT}
	cat $$(find reports/run_${RUNOUT}.orthomerged -name 'short*') | sed -n 8p  | tee -a ${DIR}/reports/qualreport.${RUNOUT}
	printf "*****  TRANSRATE SCORE ~~~~~>           " | tee -a ${DIR}/reports/qualreport.${RUNOUT}
	cat $$(find reports/transrate_${RUNOUT} -name assemblies.csv) | awk -F , '{print $$37}' | sed -n 2p | tee -a ${DIR}/reports/qualreport.${RUNOUT}
	printf "*****  TRANSRATE OPTIMAL SCORE ~~~~~>   " | tee -a ${DIR}/reports/qualreport.${RUNOUT}
	cat $$(find reports/transrate_${RUNOUT} -name assemblies.csv) | awk -F , '{print $$38}' | sed -n 2p | tee -a ${DIR}/reports/qualreport.${RUNOUT}
	printf "*****  UNIQUE GENES ORP ~~~~~>          " | tee -a ${DIR}/reports/qualreport.${RUNOUT}
	cat ${DIR}/assemblies/${RUNOUT}.unique.ORP.txt | tee -a ${DIR}/reports/qualreport.${RUNOUT}
	printf "*****  UNIQUE GENES TRINITY ~~~~~>      " | tee -a ${DIR}/reports/qualreport.${RUNOUT}
	cat ${DIR}/assemblies/diamond/${RUNOUT}.unique.trinity.txt | tee -a ${DIR}/reports/qualreport.${RUNOUT}
	printf "*****  UNIQUE GENES SPADES55 ~~~~~>     " | tee -a ${DIR}/reports/qualreport.${RUNOUT}
	cat ${DIR}/assemblies/diamond/${RUNOUT}.unique.sp55.txt | tee -a ${DIR}/reports/qualreport.${RUNOUT}
	printf "*****  UNIQUE GENES SPADES75 ~~~~~>     " | tee -a ${DIR}/reports/qualreport.${RUNOUT}
	cat ${DIR}/assemblies/diamond/${RUNOUT}.unique.sp75.txt | tee -a ${DIR}/reports/qualreport.${RUNOUT}
	printf "*****  UNIQUE GENES TRANSABYSS ~~~~~>   " | tee -a ${DIR}/reports/qualreport.${RUNOUT}
	cat ${DIR}/assemblies/diamond/${RUNOUT}.unique.transabyss.txt | tee -a ${DIR}/reports/qualreport.${RUNOUT}

	printf " \n\n"
	source ${MAKEDIR}/software/anaconda/install/bin/deactivate
