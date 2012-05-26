# coding=utf8

# Copyright (C) 2012, Leonardo Leite
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

from __future__ import unicode_literals
from django.template import RequestContext
from django.core import serializers
from django.http import HttpResponse
from django.shortcuts import render_to_response, get_object_or_404, get_list_or_404, redirect
from analises.models import *
from analise import Analise
import modelagem 


def analises(request):
    return render_to_response('analise.html')

def cmsp(request):

    """ Retorna a lista de partidos para montar a legenda do gráfico"""
    partidos = Partido.objects.order_by('numero').all()
    return render_to_response('cmsp.html', {'partidos':partidos})

# TODO
# alterar json_cmsp() para usar PeriodoAnalise em vez de analise
# testar =D

def _to_periodo_analise(coordenadas, periodo):

    pa = PeriodoAnalise()
    pa.periodo = periodo
    pa.save()
    posicoes = []
    for part, coord in coordenadas.items():
        posicao = PosicaoPartido()
        posicao.x = coord[0]
        posicao.y = coord[1]
        partido = modelagem.models.Partido.objects.filter(nome=part)[0]
        posicao.partido = partido
        posicao.save()
        posicoes.append(posicao)
    pa.posicoes = posicoes
    pa.save()
    return pa

def _faz_analises():

    if not PeriodoAnalise.objects.all():
        a20102 = Analise(None, '2011-01-01')
        a20111 = Analise('2011-01-02', '2011-07-01')
        a20112 = Analise('2011-07-02', '2012-01-01')
        a20121 = Analise('2011-01-02', None)
        analises = [a20111, a20112, a20121]
        a20102.partidos_2d()
        coadunados = [a20102.coordenadas]
        for a in analises:
            a.partidos_2d()
            coadunados.append(a.coordenadas)
        a2010 = _to_periodo_analise(coadunados[0], '20102')
        a2011a = _to_periodo_analise(coadunados[1], '20111')
        a2011b = _to_periodo_analise(coadunados[2], '20112')
        a2012 = _to_periodo_analise(coadunados[3], '20121')
        return [a2010, a2011a, a2011b, a2012]
    else:
        a2010 = PeriodoAnalise.objects.filter(periodo='20102')[0]
        a2011a = PeriodoAnalise.objects.filter(periodo='20111')[0]
        a2011b = PeriodoAnalise.objects.filter(periodo='20112')[0]
        a2012 = PeriodoAnalise.objects.filter(periodo='20121')[0]
        return [a2010, a2011a, a2011b, a2012]


def json_cmsp(request):
    """Retorna JSON tipo {periodo:{nomePartido:{numPartido:1, tamanhoPartido:1, x:1, y:1}}"""

    periodos = _faz_analises()

    analise = Analise()
    analise._inicializa_tamanhos_partidos()

    i = 0
    json = '{'
    for pa in periodos:
        json += '%s:%s ' % (pa.periodo, json_ano(pa.posicoes, analise))
        i += 1
    json = json.rstrip(', ')
    json += '}'

    return HttpResponse(json, mimetype='application/json')


def json_ano(posicoes, analise):

    json = '{'
    for posicao in posicoes.all():
        nome_partido = posicao.partido.nome
        num = posicao.partido.numero
        tamanho = analise.tamanhos_partidos[posicao.partido.nome]
        x = round(posicao.x, 2)
        y = round(posicao.y, 2)
        json += '"%s":{"numPartido":%s, "tamanhoPartido":%s, "x":%s, "y":%s}, ' % (nome_partido, num, tamanho, x, y)
    json = json.rstrip(', ')
    json += '}, '
    return json


def cdep(request):
        return render_to_response('cdep.html')


def senf(request):
        return render_to_response('senf.html')
