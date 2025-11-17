import BlueButton from "./BlueButton";
import reloadImage from '../images/reload.png'

function ReloadButton({callback, ...props}){
    return(
        <BlueButton onClick={callback} {...props}>
            <img src={reloadImage} style={{ height: 35 }} className="rotate-on-hover"/>
            <style>
                {`
                .rotate-on-hover {
                    transition: transform 0.6s ease-in-out;
                }

                .blue-button:hover .rotate-on-hover {
                    transform: rotate(360deg);
                }
                `}
            </style>
        </BlueButton>
    )
}

export default ReloadButton;