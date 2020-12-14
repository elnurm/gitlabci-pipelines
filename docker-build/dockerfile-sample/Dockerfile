FROM openjdk:11-jre
LABEL Author="Andrei_Stryia@epam.com"

RUN wget -q http://nlp.stanford.edu/software/stanford-corenlp-full-2018-10-05.zip
RUN unzip stanford-corenlp-full-2018-10-05.zip &&\
    rm stanford-corenlp-full-2018-10-05.zip

WORKDIR /stanford-corenlp-full-2018-10-05

RUN export CLASSPATH="`find . -name '*.jar'`"

ENV PORT=9000
ENV JAVA_OPTIONS=""
ENV NLP_OPTIONS="-serverProperties StanfordCoreNLP.properties"
ENV NLP_ANNOTATORS="tokenize,ssplit"
ENV NLP_THREADS=3

EXPOSE $PORT
EXPOSE 9001

CMD java -XX:+PrintFlagsFinal\
         $JAVA_OPTIONS\
         -cp "*"\
         edu.stanford.nlp.pipeline.StanfordCoreNLPServer\
         -annotators $NLP_ANNOTATORS\
         -maxCharLength 0\
         -port 9000\
         -preload $NLP_ANNOTATORS\
         -status_port 9001\
         -threads $NLP_THREADS\
         -timeout 600000\
         -quiet true\
         $NLP_OPTIONS
