function newXmlElement {
    param([xml]$xmlObject
        , [string]$Name
        , [string]$Value
        , [System.Xml.XmlAttribute[]]$attributes
        , [System.Xml.XmlElement[]]$children
        , [System.Xml.XmlElement]$Parent
    )

    $newElement = $xmlObject.CreateElement($Name, $xmlObject.FirstChild.NamespaceURI)
    if($Value) { $newElement.InnerText = $Value }
    if($attributes) {
        foreach($a in $attributes) {
            $newElement.Attributes.Append($a) | Out-Null
        }
    }

    if($children) {
        foreach($c in $children) {
            $newElement.AppendChild($c) | Out-Null
        }
    }

    if($Parent) { $Parent.AppendChild($newElement) | Out-Null }
    $newElement
}

function newXmlAttribute {
    param([xml]$xmlObject
        , [string]$Name
        , [string]$Value
        , [System.Xml.XmlElement]$Parent
    )

    $newAttribute = $xmlObject.CreateAttribute($Name)
    if($Value) { $newAttribute.InnerText = $Value }
    if($Parent) { $Parent.AppendChild($newAttribute) | Out-Null }
    $newAttribute
}