# Copyright (C) 2013, Saulo Trento
#
# This file is part of Radar Parlamentar.
# 
# Radar Parlamentar is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# Radar Parlamentar is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with Radar Parlamentar.  If not, see <http://www.gnu.org/licenses/>.

require("wnominate")
# rm(list=ls())
# options(max.print=1000)
load("rollcall_lulaII.Rdata")
dados <- rollcall_lulaII

# Corrigir nome da deputada Luciana Costa:
dados$name[dados$name=="LUCIANA COSTA\r\n\r\nLUCIANA COSTA\r\n\r\n\r\nLUCIANA COSTA"] <- "LUCIANA COSTA"
# Tirar os acentos, porque o wnominate não aceita:
dados$name[dados$name=="EMILIANO JOS\xc9"] <- "EMILIANO JOSE"
dados$name[dados$name=="JO\xc3O HERRMANN"] <- "JOAO HERRMANN"
dados$name[dados$name=="JOS\xc9 EDMAR"] <- "JOSE EDMAR"
dados$name[dados$name=="MAJOR F\xc1BIO"] <- "MAJOR FABIO"
dados$name[dados$name=="JOS\xc9 MAIA FILHO"] <- "JOSE MAIA FILHO"

# Criar uma coluna com nome+partido (identificador único de quem vota)
dados$nomepartido <- paste(dados$name," (",dados$party,")",sep="")

# Codificar votos:
dados$voto[dados$vote == "Y"] <- 1
dados$voto[dados$vote == "N"] <- -1
dados$voto[dados$vote == "A"] <- 0
dados$voto[dados$vote == "O"] <- 0


# Inicializar lista de dados que será argumento para rollcall().
dadoslist <- list()
dadoslist$desc <- "Camara dos Deputados 53a legislatura (2o mandato Lula)"
dadoslist$votes <- with(dados, tapply(voto,list(nomepartido,rollcall),c))
dadoslist$legis.names <- dimnames(dadoslist$votes)[1][[1]]
dadoslist$vote.names <- dimnames(dadoslist$votes)[2][[1]]
dadoslist$legis.data <- as.matrix(with(dados,tapply(party,nomepartido,max)))

dadoslist$votes[is.na(dadoslist$votes)] <- 0 # Transforma NA em 0.

# Criar o objeto de tipo rollcall:
rcdados <- rollcall(dadoslist, yea=1, nay=-1, missing=0, notInLegis=NA, legis.data=dadoslist$legis.data, source="Dados obtidos com Ricardo Ceneviva.")


por.partido <- function(rcobject){
  # Pega um objeto da classe rollcall e agrega votações por partido.
  # A codificação deve ser 1 para sim, -1 para não, e 0 para o resto.
  if (!class(rcobject) == "rollcall") 
    stop("O argumento rcobject deve ser da classe 'rollcall'.")

  v <- rcobject$votes
  dimnames(v)[[1]] <- as.vector(rcobject$legis.data)
  vv <- t(sapply(by(v,dimnames(v)[[1]],mean),identity))
  rcobject$legis.data <- NULL
  rcobject$votes <- vv

  return(rcobject)
}


radarpca <- function(rcobject, minvotes = 20, lop = 0.025, scale = FALSE , center = TRUE) {
  # Pega um objeto da classe rollcall, porém necessariamente com
  # votos codificados entre -1 e 1, podendo ser qualquer número real
  # neste intervalo (caso de votos agregados por partido), e faz
  # a análise de componentes principais.
  #   Argumentos:
  # minvotes -- quem votou (sim ou não) em menos do que este número
  #             de votações é excluído da análise.
  # lop -- valor entre 0 e 1. Se a fração de parlamentares que votou
  #        como minoria não for estritamente maior que este valor, a
  #        votação é considerada "unânime" e é excluída da análise.
  #        Para considerar todas as votações deve-se usar lop=-1.
  # scale -- Define se vai reescalar variáveis aleatórias (votações)
  #          para todos terem variância igual a 1.
  # center -- Define se antes da PCA vai centralizar as votações
  #           subtraindo-se a média.
  # Obs.: os argumentos minvotes possuem análogos no wnominate.
  t.inicio <- proc.time()
  resultado <- list()
  resultado$minvotes <- minvotes
  resultado$lop <- lop
  resultado$scale <- scale
  resultado$center <- center
  cat("\nPreparando para rodar o RADAR-PCA...")
  x <- rcobject$votes
  xoriginal <- x
  cat("\n\n\tVerificando dados...")

  # Vamos retirar os votos unânimes da matriz x.
  xs <- xoriginal; xs[xs==-1] <- 0; xs <- colSums( xs)
  xn <- xoriginal; xn[xn== 1] <- 0; xn <- colSums(-xn)
  total <- xs + xn
  total[total==0] <- 1
  minoria <- pmin(xn/total,xs/total)
  votos.retidos <- minoria>lop
  x <- x[,votos.retidos]
  xs <- xs[votos.retidos]
  xn <- xn[votos.retidos]
  votosminoria <- pmin(xs,xn)
  Nvotos <- dim(x)[2]
  resultado$votos.retidos <- votos.retidos
  cat("\n\t\t...",dim(xoriginal)[2]-Nvotos, "de", dim(xoriginal)[2],
      "votos descartados.")

  # Vamos tirar parlamentares que votaram pouco.
  quanto.votou <- rowSums(abs(x))
  parlams.retidos <- quanto.votou>=minvotes
  x <- x[parlams.retidos,]
  Nparlams <- dim(x)[1]
  resultado$parlams.retidos <- parlams.retidos
  cat("\n\n\t\t...",dim(xoriginal)[1]-Nparlams, "de", dim(xoriginal)[1],
      "parlamentares descartados.")
  
  # Fazer análise em si.
  cat("\n\n\t Rodando RADAR-PCA...")
  if (center == TRUE) {
    centraliza <- TRUE
  } else {
    centraliza <- rep(0,ncol(x))
  }
  
  resultado$pca <- prcomp(x,scale=scale,center=centraliza)
  resultado$rcobject <- rcobject

  resultado$x <- x
  
  sim.verdadeiro.total <- length(which(x==1))
  nao.verdadeiro.total <- length(which(x==-1))
  # Determinar o previsor.
  previsor <- with(resultado,pca$x[,c(1,2)] %*% t(pca$rotation[,c(1,2)]) + rep(1,Nparlams) %*% t(as.matrix(pca$center)))
  resultado$previsor <- previsor
  x.hat <- previsor
  x.hat[x.hat < 0] <- -1
  x.hat[x.hat >=0] <- 1
  x.hat[x == 0] <- 0
  sim.acertado <- sum(x.hat==x & x!=0 & x!=-1)
  nao.acertado <- sum(x.hat==x & x!=0 & x!=1)
  previsor1d <- with(resultado,pca$x[,1] %*% t(pca$rotation[,1]) + rep(1,Nparlams) %*% t(as.matrix(pca$center)))
  x.hat1d <- previsor1d
  x.hat1d[x.hat1d < 0] <- -1
  x.hat1d[x.hat1d >=0] <- 1
  x.hat1d[x == 0] <- 0
  # matriz com 1 nos acertos, -1 nos erros, 0 nas abstencoes:
  acertos.erros.1d <- x.hat1d * x
  acertos.erros.2d <- x.hat * x
  classif.correta1d <- length(which(acertos.erros.1d==1)) / sum(abs(acertos.erros.1d))
  classif.correta2d <- length(which(acertos.erros.2d==1)) / sum(abs(acertos.erros.2d))
  cat("\nAnalise terminada. Calculando estatisticas...")
  cat("\n\nRESUMO DA ANALISE RADAR-PCA")
  cat("\n---------------------------")
  cat("\nNumero de Parlmentares:  ",Nparlams," (",dim(xoriginal)[1]-Nparlams," excluidos)")
  cat("\nNumero de Votos:         ",Nvotos," (",dim(xoriginal)[2]-Nvotos," votos excluidos)")
  cat("\nPrevisoes de SIM:        ",sim.acertado,"de", sim.verdadeiro.total, "(",round(100*sim.acertado/sim.verdadeiro.total,1),"%) previsoes corretas")
  cat("\nPrevisoes de NAO:        ",nao.acertado,"de", nao.verdadeiro.total, "(",round(100*nao.acertado/nao.verdadeiro.total,1),"%) previsoes corretas")
  cat("\nClassificacao Correta:   ",round(100*classif.correta1d,2),"%",round(100*classif.correta2d,2),"%")

  # APRE
  so.erros.1d <- -acertos.erros.1d
  so.erros.1d[so.erros.1d==-1] <- 0
  so.erros.2d <- -acertos.erros.2d
  so.erros.2d[so.erros.2d==-1] <- 0
  erros.1d <- colSums(so.erros.1d)
  erros.2d <- colSums(so.erros.2d)
  apre.1d = sum(votosminoria - erros.1d)/sum(votosminoria)
  apre.2d = sum(votosminoria - erros.2d)/sum(votosminoria)

  cat("\nAPRE:                    ",round(apre.1d,3),round(apre.2d,3))
  
  cat("\n\nRADAR PCA levou", (proc.time()-t.inicio)[3], "segundos para executar.\n\n")
  return(resultado)
}


plotar <- function(resultado) {
  # plota resultado de uma PCA.
  xx <- resultado$pca$x[,1]
  yy <- resultado$pca$x[,2]
  symbols(xx,yy,circles=rep(1,length(xx)),inches=0.2)
  text(xx,yy,dimnames(resultado$pca$x)[[1]])
  return
}


compara <- function(resultado,wnobject) {
  # Compara os resultados de uma PCA com os resultados do wnominate.
  # Argumentos:
  #   resultado -- deve ser um objeto retornado pela função radarpca.
  #   wnobject -- deve ser um objeto retornado pela função wnominate
  wndim1 <- wnobject$legislators$coord1D
  wndim1 <- wndim1[!is.na(wndim1)]
  rpdim1 <- resultado$pca$x[,1]
  if (length(rpdim1) != length(wndim1))
    stop("radarpca e wnominate nao tem os mesmos numeros de parlamentares.\n Ou os dados originais nao eram os mesmos, ou as opcoes lop e minvotes usadas nao foram iguais.")
  pears <- paste("Pearson =",format(cor(-rpdim1,wndim1),digits=4,nsmall=3))
  plot(wndim1,-rpdim1,
       xlab="W-Nominate",
       ylab="Radar-PCA",
       main="53a Legislatura (Lula-2)",
       sub=pears
       )
}


ver.votacao <- function(resultado,numero.votacao) {
  # Faz um plot de uma votação específica.
  votacao = resultado$x[,numero.votacao]
  variancia = var(votacao)
  if ( sum(votacao==-1|votacao==0|votacao==1)==length(votacao) ) {
    # Os votos analisados sao somente sim/nao ou "zero".
    alturas = c(sum(votacao==-1),sum(votacao==0),sum(votacao==1))
    textonao = paste("N =",alturas[1],"(",round(100*alturas[1]/length(votacao),2),"%)")
    textoout = paste("O =",alturas[2],"(",round(100*alturas[2]/length(votacao),2),"%)")
    textosim = paste("S =",alturas[3],"(",round(100*alturas[3]/length(votacao),2),"%)")
    barplot(alturas,names.arg=c(textonao,textoout,textosim),main=paste("Votacao",numero.votacao,),sub=paste("Variancia Amostral =",round(variancia,5)),ylim=c(0,length(votacao)))
  } else {
    # Os "votos" são valores reais entre -1 (nao) e 1 (sim).
    # Vou fazer um histograma.
    hist(votacao,breaks=c(-1,-.6,-.2,.2,.6,1),freq=TRUE,main=paste("Votacao Numero",numero.votacao),sub=paste("Variancia Amostral =",round(variancia,5)),ylim=c(0,length(votacao)))
  }
# para talvez uso futuro nesta funcao:
#  partidos = resultado$rcobject$legis.data[resultado$votos.retidos]
}


ver.pc <- function(resultado,numero.pc) {
  # Faz um plot dos coeficientes das votações que formam uma dada PC.
  pca <- resultado$pca
  alturas <- pca$rotation[,numero.pc]
  xvotos <- seq(1,ncol(pca$rotation))
  alt.max <- max(alturas) 
  plot(xvotos,abs(alturas),type="s",main=NULL,sub=NULL,xlab="",ylab="",ylim=c(-alt.max,alt.max))
  barplot(alturas,sub=paste("Variancia Explicada =",round(pca$sdev[numero.pc]^2,2),"(",round(100*(pca$sdev[numero.pc]^2)/sum(pca$sdev^2),1),"%)"),space=0,border=NA,add=TRUE,xlab=NULL,names.arg=" ")
}

# OBSERVAÇÕES:

# Se um parlamentar muda de partido, ele é considerado como
# um parlamentar diferente. Ou seja, o par (nome,partido) define
# o parlamentar.

# Nos dados rollcall_lulaII, a
# coluna 'id' não é concebida dessa forma, havendo 1 id por nome,
# exceto para o deputado 'BARBOSA NETO', que aparece com dois ids
# diferentes, a saber id=2646 e id=4372. Logo este id não será usado.

# Na matriz de votações, usaremos a codificação do radar.
# Abaixo a comparação com a de Poole e Rosenthal e a do pacote pscl:
#
# Yea : 1 2 3 (pscl:1)  (usaremos 1)
# Nay : 4 5 6 (pscl:0)  (usaremos -1)
# Abs.: 7 8 9 (pscl:NA) (usaremos 0)
# não está na legislatura: 0 (pscl:9) (usaremos 0)
#
