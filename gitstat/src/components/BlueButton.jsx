import { Button } from "antd";

function BlueButton({children, callback, ...props}) {
    return (
        <Button onClick={callback} className="blue-button" {...props}>
            {children}
            <style jsx>
                {`
                .blue-button{
                    background-color: #4A61BD;
                    border: 3px solid #627FEE !important;
                }

                .blue-button:hover{
                    background-color: #627FEE !important;
                    border: 3px solid #627FEE !important;
                }
                `}
            </style>
        </Button>
    )
}

export default BlueButton;