from django.core import serializers
from modelagem import models
import re
import sys
import os

#MODULE_DIR = os.path.abspath(os.path.dirname(__file__))
MODULE_DIR = os.getcwd() + '/exportadores/'

def main():
	deserialize_partido()
	deserialize_casa_legislativa()
	deserialize_parlamentar()
	deserialize_legislatura()
	deserialize_proposicao()
	deserialize_votacao()
	deserialize_voto()

def deserialize_partido():
	XMLSerializer = serializers.get_serializer("xml")
	xml_serializer = XMLSerializer()
	filepath = os.path.join(MODULE_DIR, 'dados/partido.xml')
	out = open(filepath, "r")
	data = xml_serializer.getvalue()
	
	for partido in serializers.deserialize("xml", data):
    		partido.save()	

def deserialize_casa_legislativa():
	print ("\nIsso aqui eh :" + MODULE_DIR + "\n")
	XMLSerializer = serializers.get_serializer("xml")
	xml_serializer = XMLSerializer()
	filepath = os.path.join(MODULE_DIR, 'dados/casa_legislativa.xml')
	out = open(filepath, "r")
	#data = xml_serializer.getvalue()
	
	for casa_legislativa in serializers.deserialize("xml", out):
    		casa_legislativa.save()

def deserialize_parlamentar():
	XMLSerializer = serializers.get_serializer("xml")
	xml_serializer = XMLSerializer()
	filepath = os.path.join(MODULE_DIR, 'dados/parlamentar.xml')
	out = open(filepath, "r")
	data = xml_serializer.getvalue()
	
	for parlamentar in serializers.deserialize("xml", data):
    		parlamentar.save()

def deserialize_legislatura():
	XMLSerializer = serializers.get_serializer("xml")
	xml_serializer = XMLSerializer()
	filepath = os.path.join(MODULE_DIR, 'dados/legislatura.xml')
	out = open(filepath, "r")
	data = xml_serializer.getvalue()
	
	for legislatura in serializers.deserialize("xml", data):
    		legislatura.save()

def deserialize_proposicao():
	XMLSerializer = serializers.get_serializer("xml")
	xml_serializer = XMLSerializer()
	filepath = os.path.join(MODULE_DIR, 'dados/proposicao.xml')
	out = open(filepath, "r")
	data = xml_serializer.getvalue()
	
	for proposicao in serializers.deserialize("xml", data):
    		proposicao.save()

def deserialize_votacao():
	XMLSerializer = serializers.get_serializer("xml")
	xml_serializer = XMLSerializer()
	filepath = os.path.join(MODULE_DIR, 'dados/votacao.xml')
	out = open(filepath, "r")
	data = xml_serializer.getvalue()
	
	for votacao in serializers.deserialize("xml", data):
    		votacao.save()

def deserialize_voto():
	XMLSerializer = serializers.get_serializer("xml")
	xml_serializer = XMLSerializer()
	filepath = os.path.join(MODULE_DIR, 'dados/voto.xml')
	out = open(filepath, "r")
	data = xml_serializer.getvalue()
	
	for voto in serializers.deserialize("xml", data):
    		voto.save()





	
