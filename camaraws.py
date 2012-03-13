# -*- coding: utf-8 -*-

# Copyright (C) 2012, Leonardo Leite, Diego Rabatone
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program. If not, see <http://www.gnu.org/licenses/>.

"""Módulo camaraws -- requisições para os Web Services da câmara

Funcões:
obter_votacao -- Obtém votacões e detalhes de uma proposicão
"""

from model import Proposicao
import urllib.request
import xml.etree.ElementTree as etree
import io

OBTER_VOTACOES_PROPOSICAO = 'http://www.camara.gov.br/sitcamaraws/Proposicoes.asmx/ObterVotacaoProposicao?tipo=%s&numero=%s&ano=%s'
OBTER_INFOS_PROPOSICAO_POR_DADOS = 'http://www.camara.gov.br/sitcamaraws/Proposicoes.asmx/ObterProposicao?tipo=%s&numero=%s&ano=%s'
OBTER_INFOS_PROPOSICAO_POR_ID = 'http://www.camara.gov.br/sitcamaraws/Proposicoes.asmx/ObterProposicaoPorID?idProp=%s'

def obter_votacao(tipo, num, ano):
    """Obtém votacões e detalhes de uma proposicão

    Argumentos:
    tipo, num, ano -- strings que caracterizam a proposicão

    Retorna:
    Uma proposicão como um objeto da classe model.Proposicao

    Excessões:
    urllib.error.HTTPError -- proposicão não encontrada
    """
    url  = OBTER_VOTACOES_PROPOSICAO % (tipo, num, ano)
    try:
        xml = urllib.request.urlopen(url).read()
    except urllib.error.HTTPError:
        return None
    xml = str(xml, "utf-8") # aqui é o xml da votação
    proposicao = Proposicao.fromxml(xml)

    xml = obter_proposicao(tipo, num, ano) #aqui é o xml com mais detalhes sobre a proposição
    xml = str(xml, "utf-8")
    tree = etree.parse(io.StringIO(xml))
    prop.ementa = tree.find('Ementa').text
    prop.explicacao = tree.find('ExplicacaoEmenta').text
    prop.situacao = tree.find('Situacao').text
    return prop

def obter_votacao(prop_id, tipo, num, ano):
    """Obtém votacões de detalhes de uma proposicão utilizando o ID da proposição -- deprecated
    A funcão obter_votacao(tipo, num, ano) retorna as mesmas informacões

    Argumentos:
    tipo, num, ano -- strings que caracterizam a proposicão
    prop_id -- id da proposicão no sistema da câmara; pode ser encontrado em resultados/votadas.txt

    Retorna:
    Uma proposicão como um objeto da classe model.Proposicao

    Excessões:
    urllib.error.HTTPError -- proposicão não encontrada
    """
    url = OBTER_VOTACOES_PROPOSICAO % (tipo, num, ano)
    try:
        xml = urllib.request.urlopen(url).read()
    except urllib.error.HTTPError:
        return None
    xml = str(xml, "utf-8") # aqui é o xml da votação
    prop = Proposicao.fromxml(xml)
    prop.id = prop_id

    xml = obter_proposicao(prop_id) # aqui é o xml com mais detalhes sobre a proposição
    xml = str(xml, "utf-8")
    tree = etree.parse(io.StringIO(xml))
    prop.ementa = tree.find('Ementa').text
    prop.explicacao = tree.find('ExplicacaoEmenta').text
    prop.situacao = tree.find('Situacao').text
    return prop

def obter_proposicao(tipo, num, ano):
    """Obtém detalhes da proposição por tipo, número e ano

    Argumentos:
    tipo, num, ano -- strings que caracterizam a proposicão

    Retorna:
    Um xml represenando a proposicão como um objeto da classe bytes
    """
    url = OBTER_INFOS_PROPOSICAO_POR_DADOS % (tipo, num, ano)
    xml = urllib.request.urlopen(url).read()
    return xml

def obter_proposicao(prop_id):
    """Obtém detalhes da proposição pelo id da proposicão

    Argumentos:
    prop_id -- id da proposicão no sistema da câmara; pode ser encontrado em resultados/votadas.txt

    Retorna:
    Um xml represenando a proposicão como um objeto da classe bytes
    """
    url = OBTER_INFOS_PROPOSICAO_POR_ID % prop_id
    xml = urllib.request.urlopen(url).read()
    return xml
