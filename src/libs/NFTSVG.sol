// SPDX-License-Identifier: MIT
pragma solidity >=0.7.6;

import "@oc/utils/Strings.sol";
import "@oc/utils/Base64.sol";
import "self/interfaces/INFTSVG.sol";

/// @title NFTSVG
/// @notice Provides a function for generating an SVG associated with a Investment NFT
contract NFTSVG is INFTSVG {
    using Strings for uint256;

    function generateNFT(SVGParams memory params) public pure override returns (string memory svg) {
        svg = string(
            abi.encodePacked(
                headerSVG(params),
                investmentSVG(params.investment),
                mySharesSVG(params.mySharesStr, params.claimTokenAddress),
                tokenIdSVG(params.tokenId),
                totalInvestmentSVG(params.totalAmountStr, params.claimTokenAddress),
                footerSVG(params)
            )
        );
    }

    function headerSVG(SVGParams memory params) internal pure returns (string memory svg) {
        svg = string(
            abi.encodePacked(
                '<svg width="360" height="494" fill="none" xmlns="http://www.w3.org/2000/svg"><g clip-path="url(#clip0_1634_41705)"><rect x="285" y="10" width="64" height="64" rx="16" fill="url(#paint0_linear_1634_41705)"/><mask id="a" style="mask-type:alpha" maskUnits="userSpaceOnUse" x="0" y="0" width="360" height="494"><path fill-rule="evenodd" clip-rule="evenodd" d="M309.289 5.858A19.997 19.997 0 00295.147 0H20C8.954 0 0 8.954 0 20v454c0 11.046 8.954 20 20 20h320c11.046 0 20-8.954 20-20V64.853a19.999 19.999 0 00-5.858-14.142L309.289 5.858z" fill="#ABC8FF"/><path fill-rule="evenodd" clip-rule="evenodd" d="M309.289 5.858A19.997 19.997 0 00295.147 0H20C8.954 0 0 8.954 0 20v454c0 11.046 8.954 20 20 20h320c11.046 0 20-8.954 20-20V64.853a19.999 19.999 0 00-5.858-14.142L309.289 5.858z" fill="#001AFF" fill-opacity=".3"/><path fill-rule="evenodd" clip-rule="evenodd" d="M309.289 5.858A19.997 19.997 0 00295.147 0H20C8.954 0 0 8.954 0 20v454c0 11.046 8.954 20 20 20h320c11.046 0 20-8.954 20-20V64.853a19.999 19.999 0 00-5.858-14.142L309.289 5.858z" fill="#4CAEF5" fill-opacity=".37"/><path fill-rule="evenodd" clip-rule="evenodd" d="M309.289 5.858A19.997 19.997 0 00295.147 0H20C8.954 0 0 8.954 0 20v454c0 11.046 8.954 20 20 20h320c11.046 0 20-8.954 20-20V64.853a19.999 19.999 0 00-5.858-14.142L309.289 5.858z" fill="url(#paint1_linear_1634_41705)"/></mask><g mask="url(#a)"><mask id="b" maskUnits="userSpaceOnUse" x="-4" y="-4" width="368" height="502" fill="#000"><path fill="#fff" d="M-4-4h368v502H-4z"/><path fill-rule="evenodd" clip-rule="evenodd" d="M303.289 11.858A19.997 19.997 0 00289.147 6H26C14.954 6 6 14.954 6 26v442c0 11.046 8.954 20 20 20h308c11.046 0 20-8.954 20-20V70.853a19.999 19.999 0 00-5.858-14.142l-44.853-44.853z"/></mask><path fill-rule="evenodd" clip-rule="evenodd" d="M303.289 11.858A19.997 19.997 0 00289.147 6H26C14.954 6 6 14.954 6 26v442c0 11.046 8.954 20 20 20h308c11.046 0 20-8.954 20-20V70.853a19.999 19.999 0 00-5.858-14.142l-44.853-44.853z" fill="url(#paint2_linear_1634_41705)"/><path d="M348.142 56.71l7.071-7.07-7.071 7.07zm-44.853-44.852l-7.071 7.07 7.071-7.07zM26 16h263.147V-4H26v20zM16 468V26H-4v442h20zm318 10H26v20h308v-20zm10-407.147V468h20V70.853h-20zm11.213-21.213L310.36 4.787l-14.142 14.142 44.853 44.853 14.142-14.142zM364 70.853a30 30 0 00-8.787-21.213l-14.142 14.142a10.002 10.002 0 012.929 7.07h20zM334 498c16.569 0 30-13.431 30-30h-20c0 5.523-4.477 10-10 10v20zM-4 468c0 16.569 13.431 30 30 30v-20c-5.523 0-10-4.477-10-10H-4zM289.147 16a10 10 0 017.071 2.929L310.36 4.787A29.998 29.998 0 00289.147-4v20zM26-4C9.431-4-4 9.431-4 26h20c0-5.523 4.477-10 10-10V-4z" fill="url(#paint3_linear_1634_41705)" mask="url(#b)"/><path opacity=".5" d="M140 362.801v-200m-100 100h200m-29.389 71.198l-141.39-141.39m-.23 140.99l141.419-141.41m-70.411 113.802c23.638 0 42.8-19.163 42.8-42.8 0-23.638-19.162-42.8-42.8-42.8m0 85.6c-23.638 0-42.8-19.163-42.8-42.8 0-23.638 19.162-42.8 42.8-42.8m0 85.6c55.229 0 100.001-19.163 100.001-42.8 0-23.638-44.772-42.8-100.001-42.8m0 85.6c-55.228 0-99.999-19.163-99.999-42.8 0-23.638 44.77-42.8 99.999-42.8M240 263.189c0 55.229-44.772 100-100 100s-100-44.771-100-100c0-55.228 44.772-100 100-100s100 44.772 100 100zm-56.21 0c0 55.229-19.163 100-42.8 100-23.638 0-42.8-44.771-42.8-100 0-55.228 19.162-100 42.8-100 23.637 0 42.8 44.772 42.8 100zM212.231 262c0 55.229-32.518 100-72.63 100-40.113 0-72.63-44.771-72.63-100 0-55.228 32.517-100 72.63-100 40.112 0 72.63 44.772 72.63 100z" stroke="url(#paint4_linear_1634_41705)" stroke-miterlimit="10"/><g filter="url(#filter0_f_1634_41705)"><ellipse cx="165" cy="35" rx="195" ry="124" fill="#',
                params.color3,
                '"/></g><g filter="url(#filter1_f_1634_41705)"><circle cx="256" cy="332" r="124" fill="#',
                params.color1,
                '" fill-opacity=".5"/></g>'
            )
        );
    }

    function footerSVG(SVGParams memory params) internal pure returns (string memory svg) {
        svg = string(
            abi.encodePacked(
                '</g><g style="mix-blend-mode:color-dodge" opacity=".4"><mask id="c" style="mask-type:alpha" maskUnits="userSpaceOnUse" x="35" y="157" width="212" height="212"><circle cx="141" cy="263" r="105.593" fill="url(#paint9_linear_1634_41705)"/></mask><g mask="url(#c)"><g filter="url(#filter3_ii_1634_41705)"><path d="M202.964 263.001c0 34.221-27.742 61.963-61.963 61.963-34.221 0-61.962-27.742-61.962-61.963 0-34.221 27.741-61.962 61.962-61.962 34.221 0 61.963 27.741 61.963 61.962zm-95.779 0c0 18.676 15.14 33.816 33.816 33.816 18.676 0 33.816-15.14 33.816-33.816 0-18.676-15.14-33.816-33.816-33.816-18.676 0-33.816 15.14-33.816 33.816z" fill="url(#paint10_linear_1634_41705)"/><path d="M202.964 263.001c0 34.221-27.742 61.963-61.963 61.963-34.221 0-61.962-27.742-61.962-61.963 0-34.221 27.741-61.962 61.962-61.962 34.221 0 61.963 27.741 61.963 61.962zm-95.779 0c0 18.676 15.14 33.816 33.816 33.816 18.676 0 33.816-15.14 33.816-33.816 0-18.676-15.14-33.816-33.816-33.816-18.676 0-33.816 15.14-33.816 33.816z" fill="#7E471F" fill-opacity=".2"/></g><g filter="url(#filter4_ii_1634_41705)"><path d="M162.363 263.002c0 11.797-9.564 21.361-21.361 21.361-11.798 0-21.361-9.564-21.361-21.361 0-11.798 9.563-21.361 21.361-21.361 11.797 0 21.361 9.563 21.361 21.361zm-33.019 0c0 6.438 5.219 11.658 11.658 11.658 6.438 0 11.658-5.22 11.658-11.658 0-6.439-5.22-11.658-11.658-11.658-6.439 0-11.658 5.219-11.658 11.658z" fill="url(#paint11_linear_1634_41705)"/><path d="M162.363 263.002c0 11.797-9.564 21.361-21.361 21.361-11.798 0-21.361-9.564-21.361-21.361 0-11.798 9.563-21.361 21.361-21.361 11.797 0 21.361 9.563 21.361 21.361zm-33.019 0c0 6.438 5.219 11.658 11.658 11.658 6.438 0 11.658-5.22 11.658-11.658 0-6.439-5.22-11.658-11.658-11.658-6.439 0-11.658 5.219-11.658 11.658z" fill="#7E471F" fill-opacity=".2"/></g><g filter="url(#filter5_iif_1634_41705)"><path d="M246.595 263.002c0 58.317-47.276 105.593-105.593 105.593-58.318 0-105.594-47.276-105.594-105.593 0-58.318 47.276-105.594 105.594-105.594 58.317 0 105.593 47.276 105.593 105.594zm-188.028 0c0 45.527 36.907 82.434 82.435 82.434 45.527 0 82.434-36.907 82.434-82.434 0-45.528-36.907-82.435-82.434-82.435-45.528 0-82.435 36.907-82.435 82.435z" fill="url(#paint12_linear_1634_41705)"/><path d="M246.595 263.002c0 58.317-47.276 105.593-105.593 105.593-58.318 0-105.594-47.276-105.594-105.593 0-58.318 47.276-105.594 105.594-105.594 58.317 0 105.593 47.276 105.593 105.594zm-188.028 0c0 45.527 36.907 82.434 82.435 82.434 45.527 0 82.434-36.907 82.434-82.434 0-45.528-36.907-82.435-82.434-82.435-45.528 0-82.435 36.907-82.435 82.435z" fill="#7E471F" fill-opacity=".2"/></g></g></g></g><defs><linearGradient id="paint0_linear_1634_41705" x1="294" y1="10" x2="349.625" y2="10.634" gradientUnits="userSpaceOnUse"><stop stop-color="#',
                params.color1,
                '"/><stop offset="1" stop-color="#',
                params.color2,
                '"/></linearGradient><linearGradient id="paint1_linear_1634_41705" x1="180" y1="0" x2="180" y2="480" gradientUnits="userSpaceOnUse"><stop stop-color="#1F333A" stop-opacity=".52"/><stop offset="1" stop-color="#2A5161"/></linearGradient><linearGradient id="paint2_linear_1634_41705" x1="180" y1="6" x2="180" y2="488" gradientUnits="userSpaceOnUse"><stop stop-color="#',
                params.color3,
                '"/><stop offset=".838" stop-color="#',
                params.color2,
                '"/></linearGradient><linearGradient id="paint3_linear_1634_41705" x1="180" y1="6" x2="180" y2="397" gradientUnits="userSpaceOnUse"><stop stop-color="#fff" stop-opacity=".2"/><stop offset="1" stop-color="#fff" stop-opacity=".1"/></linearGradient><linearGradient id="paint4_linear_1634_41705" x1="139.601" y1="162" x2="139.601" y2="362" gradientUnits="userSpaceOnUse"><stop stop-color="#fff"/><stop offset="1" stop-color="#fff" stop-opacity=".31"/></linearGradient><linearGradient id="paint5_linear_1634_41705" x1="80.581" y1="405.952" x2="292.977" y2="547.209" gradientUnits="userSpaceOnUse"><stop stop-color="#FFE7D0" stop-opacity=".48"/><stop offset="1" stop-color="#FFE9D9" stop-opacity=".12"/></linearGradient><linearGradient id="paint6_linear_1634_41705" x1="67.19" y1="437.5" x2="268.902" y2="437.5" gradientUnits="userSpaceOnUse"><stop stop-color="#fff" stop-opacity=".2"/><stop offset="1" stop-color="#fff" stop-opacity=".1"/></linearGradient><linearGradient id="paint9_linear_1634_41705" x1="187.373" y1="368.593" x2="148.139" y2="207.374" gradientUnits="userSpaceOnUse"><stop offset=".138" stop-opacity="0"/><stop offset="1"/></linearGradient><linearGradient id="paint10_linear_1634_41705" x1="118.861" y1="147.184" x2="190.071" y2="252.862" gradientUnits="userSpaceOnUse"><stop stop-color="#949494"/><stop offset=".635" stop-color="#181818"/><stop offset="1" stop-color="#1D1D1D"/></linearGradient><linearGradient id="paint11_linear_1634_41705" x1="133.369" y1="223.075" x2="157.918" y2="259.506" gradientUnits="userSpaceOnUse"><stop stop-color="#949494"/><stop offset=".635" stop-color="#181818"/><stop offset="1" stop-color="#1D1D1D"/></linearGradient><linearGradient id="paint12_linear_1634_41705" x1="103.271" y1="65.632" x2="224.624" y2="245.722" gradientUnits="userSpaceOnUse"><stop stop-color="#949494"/><stop offset=".635" stop-color="#181818"/><stop offset="1" stop-color="#1D1D1D"/></linearGradient><filter id="filter0_f_1634_41705" x="-225" y="-284" width="780" height="638" filterUnits="userSpaceOnUse" color-interpolation-filters="sRGB"><feFlood flood-opacity="0" result="BackgroundImageFix"/><feBlend in="SourceGraphic" in2="BackgroundImageFix" result="shape"/><feGaussianBlur stdDeviation="97.5" result="effect1_foregroundBlur_1634_41705"/></filter><filter id="filter1_f_1634_41705" x="-124" y="-48" width="760" height="760" filterUnits="userSpaceOnUse" color-interpolation-filters="sRGB"><feFlood flood-opacity="0" result="BackgroundImageFix"/><feBlend in="SourceGraphic" in2="BackgroundImageFix" result="shape"/><feGaussianBlur stdDeviation="128" result="effect1_foregroundBlur_1634_41705"/></filter><filter id="filter2_d_1634_41705" x="13.217" y="23.651" width="216.435" height="76.501" filterUnits="userSpaceOnUse" color-interpolation-filters="sRGB"><feFlood flood-opacity="0" result="BackgroundImageFix"/><feColorMatrix in="SourceAlpha" values="0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 127 0" result="hardAlpha"/><feOffset dy="1.541"/><feGaussianBlur stdDeviation="6.153"/><feComposite in2="hardAlpha" operator="out"/><feColorMatrix values="0 0 0 0 1 0 0 0 0 1 0 0 0 0 1 0 0 0 0.85 0"/><feBlend in2="BackgroundImageFix" result="effect1_dropShadow_1634_41705"/><feBlend in="SourceGraphic" in2="effect1_dropShadow_1634_41705" result="shape"/></filter><filter id="filter3_ii_1634_41705" x="79.039" y="201.039" width="127.916" height="131.196" filterUnits="userSpaceOnUse" color-interpolation-filters="sRGB"><feFlood flood-opacity="0" result="BackgroundImageFix"/><feBlend in="SourceGraphic" in2="BackgroundImageFix" result="shape"/><feColorMatrix in="SourceAlpha" values="0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 127 0" result="hardAlpha"/><feOffset dy="7.272"/><feGaussianBlur stdDeviation="5.908"/><feComposite in2="hardAlpha" operator="arithmetic" k2="-1" k3="1"/><feColorMatrix values="0 0 0 0 1 0 0 0 0 1 0 0 0 0 1 0 0 0 0.8 0"/><feBlend mode="lighten" in2="shape" result="effect1_innerShadow_1634_41705"/><feColorMatrix in="SourceAlpha" values="0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 127 0" result="hardAlpha"/><feOffset dx="3.992" dy="2.329"/><feGaussianBlur stdDeviation="2.329"/><feComposite in2="hardAlpha" operator="arithmetic" k2="-1" k3="1"/><feColorMatrix values="0 0 0 0 0.168627 0 0 0 0 0.180392 0 0 0 0 0.239216 0 0 0 0.9 0"/><feBlend mode="multiply" in2="effect1_innerShadow_1634_41705" result="effect2_innerShadow_1634_41705"/></filter><filter id="filter4_ii_1634_41705" x="119.641" y="241.641" width="46.715" height="49.995" filterUnits="userSpaceOnUse" color-interpolation-filters="sRGB"><feFlood flood-opacity="0" result="BackgroundImageFix"/><feBlend in="SourceGraphic" in2="BackgroundImageFix" result="shape"/><feColorMatrix in="SourceAlpha" values="0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 127 0" result="hardAlpha"/><feOffset dy="7.272"/><feGaussianBlur stdDeviation="5.908"/><feComposite in2="hardAlpha" operator="arithmetic" k2="-1" k3="1"/><feColorMatrix values="0 0 0 0 1 0 0 0 0 1 0 0 0 0 1 0 0 0 0.8 0"/><feBlend mode="lighten" in2="shape" result="effect1_innerShadow_1634_41705"/><feColorMatrix in="SourceAlpha" values="0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 127 0" result="hardAlpha"/><feOffset dx="3.992" dy="2.329"/><feGaussianBlur stdDeviation="2.329"/><feComposite in2="hardAlpha" operator="arithmetic" k2="-1" k3="1"/><feColorMatrix values="0 0 0 0 0.168627 0 0 0 0 0.180392 0 0 0 0 0.239216 0 0 0 0.9 0"/><feBlend mode="multiply" in2="effect1_innerShadow_1634_41705" result="effect2_innerShadow_1634_41705"/></filter><filter id="filter5_iif_1634_41705" x="23.805" y="145.805" width="234.394" height="234.394" filterUnits="userSpaceOnUse" color-interpolation-filters="sRGB"><feFlood flood-opacity="0" result="BackgroundImageFix"/><feBlend in="SourceGraphic" in2="BackgroundImageFix" result="shape"/><feColorMatrix in="SourceAlpha" values="0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 127 0" result="hardAlpha"/><feOffset dy="7.272"/><feGaussianBlur stdDeviation="5.908"/><feComposite in2="hardAlpha" operator="arithmetic" k2="-1" k3="1"/><feColorMatrix values="0 0 0 0 1 0 0 0 0 1 0 0 0 0 1 0 0 0 0.8 0"/><feBlend mode="lighten" in2="shape" result="effect1_innerShadow_1634_41705"/><feColorMatrix in="SourceAlpha" values="0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 127 0" result="hardAlpha"/><feOffset dx="3.992" dy="2.329"/><feGaussianBlur stdDeviation="2.329"/><feComposite in2="hardAlpha" operator="arithmetic" k2="-1" k3="1"/><feColorMatrix values="0 0 0 0 0.168627 0 0 0 0 0.180392 0 0 0 0 0.239216 0 0 0 0.9 0"/><feBlend mode="multiply" in2="effect1_innerShadow_1634_41705" result="effect2_innerShadow_1634_41705"/><feGaussianBlur stdDeviation="5.802" result="effect3_foregroundBlur_1634_41705"/></filter><clipPath id="clip0_1634_41705"><path fill="#fff" d="M0 0h360v494H0z"/></clipPath></defs></svg>'
            )
        );
    }

    function investmentSVG(string memory investment) internal pure returns (string memory svg) {
        uint256 investmentFontSize = 37 - bytes(investment).length;
        if (investmentFontSize < 10) {
            investmentFontSize = 10;
        }
        svg = string(
            abi.encodePacked(
                '<g filter="url(#filter2_d_1634_41705)"><text fill="white" xml:space="preserve" style="white-space: pre" font-family="Red Rose" font-size="',
                investmentFontSize.toString(),
                '" letter-spacing="3.08239px">',
                '<tspan x="24" y="53.1161">',
                investment,
                ' &#10;</tspan><tspan x="24" y="86.3065">INVESTING</tspan></text></g>'
            )
        );
    }

    function totalInvestmentSVG(string memory totalInvestAmountStr, address claimTokenAddress) internal pure returns (string memory svg) {
        string memory financingTag = "Total financing";
        if (claimTokenAddress != address(0)) {
            financingTag = "Total claimable";
        }
        svg = string(
            abi.encodePacked(
                '<rect x="19" y="351" width="',
                (170 + 5 * bytes(totalInvestAmountStr).length).toString(),
                '" height="25" rx="10" fill="#00031B" fill-opacity="0.2"/><text opacity="0.7" fill="white" xml:space="preserve" style="white-space: pre" font-family="Inter" font-size="14" letter-spacing="0.005em"><tspan x="27" y="368.591">',
                financingTag,
                ': </tspan></text><text fill="white" xml:space="preserve" style="white-space: pre" font-family="Inter" font-size="14" letter-spacing="0.005em"><tspan x="133" y="368.591">',
                totalInvestAmountStr,
                "</tspan></text>"
            )
        );
    }

    function tokenIdSVG(string memory tokenId) internal pure returns (string memory svg) {
        svg = string(
            abi.encodePacked(
                '<rect x="19" y="322" width="',
                (110 + 5 * bytes(tokenId).length).toString(),
                '" height="25" rx="10" fill="#00031B" fill-opacity="0.2"/><text opacity="0.7" fill="white" xml:space="preserve" style="white-space: pre" font-family="Inter" font-size="14" letter-spacing="0.005em"><tspan x="27" y="339.591">Token ID:</tspan></text><text fill="white" xml:space="preserve" style="white-space: pre" font-family="Inter" font-size="14" letter-spacing="0.005em"><tspan x="93" y="339.591">',
                tokenId,
                "</tspan></text>"
            )
        );
    }

    function mySharesSVG(string memory mySharesStr, address claimTokenAddress) internal pure returns (string memory svg) {
        uint256 mySharesLength = (150 - 2 * bytes(mySharesStr).length);
        string memory topTag = "MY SHARES";
        if (claimTokenAddress != address(0)) {
            topTag = "MY CLAIMS";
        }
        svg = string(
            abi.encodePacked(
                '<rect x="20" y="400" width="321" height="75" rx="12" fill="url(#paint5_linear_1634_41705)" fill-opacity=".45"/><path fill-rule="evenodd" clip-rule="evenodd" d="M22 463v-51c0-5.523 4.477-10 10-10h80v-2H32c-6.627 0-12 5.373-12 12v51c0 6.627 5.373 12 12 12h298c6.627 0 12-5.373 12-12v-51c0-6.627-5.373-12-12-12h-79v2h79c5.523 0 10 4.477 10 10v51c0 5.523-4.477 10-10 10H32c-5.523 0-10-4.477-10-10z" fill="url(#paint6_linear_1634_41705)"/><text fill="#fff" style="white-space:pre" font-family="Poppins" font-size="20" font-weight="600" letter-spacing="0"><tspan x="',
                mySharesLength.toString(),
                '" y="445">',
                mySharesStr,
                '</tspan></text><text opacity="0.5" fill="white" xml:space="preserve" style="white-space: pre" font-family="Inter" font-size="14" letter-spacing="0.005em"><tspan x="142" y="405.591">',
                topTag,
                '</tspan></text>'
            )
        );
    }
}
