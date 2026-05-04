# Next Steps

The solution has no build errors following the transformation. Below are steps to validate, test, and deploy the project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the target framework moniker (TFM) is set to a supported cross-platform .NET version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure this matches the version of the .NET SDK you have installed. You can check your installed SDKs with:

```bash
dotnet --list-sdks
```

## 2. Restore Dependencies

Run a NuGet restore to confirm all packages resolve correctly against the new TFM:

```bash
dotnet restore
```

Review the output for any warnings about packages that do not support the target framework or that have been replaced by inbox .NET APIs.

## 3. Build the Solution

Perform a clean build to confirm there are no errors or warnings that were not present during the initial transformation check:

```bash
dotnet build --configuration Release
```

Address any warnings related to deprecated APIs or platform compatibility analyzers (`CA1416`, etc.) before proceeding.

## 4. Run Existing Tests

If the solution contains test projects, execute them to verify behavioral correctness has been preserved:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review any failing tests to determine whether they indicate a regression introduced during migration or a pre-existing issue.

## 5. Check for Windows-Specific API Usage

Because this is a cross-platform migration, audit the codebase for APIs that are Windows-only. The .NET platform compatibility analyzer will flag these with warning `CA1416`. Common areas to check include:

- `Microsoft.Win32` registry access
- `System.Windows.Forms` or `System.Drawing.Common` (GDI+)
- P/Invoke calls to Windows DLLs
- `System.Security.Principal.WindowsIdentity`

If Windows-only APIs are required, annotate the call sites with `[SupportedOSPlatform("windows")]` or add a runtime OS guard:

```csharp
if (OperatingSystem.IsWindows())
{
    // Windows-specific code
}
```

## 6. Validate Configuration and App Settings

If the project previously used `App.config` or `Web.config`, confirm that settings have been migrated to `appsettings.json` or environment variables where appropriate, as `ConfigurationManager` behavior differs in .NET compared to .NET Framework.

## 7. Smoke Test on a Non-Windows Platform (if applicable)

If cross-platform execution is a requirement, run the compiled output on Linux or macOS to surface any remaining platform-specific issues:

```bash
dotnet run --configuration Release
```

## 8. Review Output Artifacts

Confirm the output assembly type (executable vs. class library) and output paths are correct in the `.csproj`:

```xml
<OutputType>Exe</OutputType>  <!-- or Library -->
<AssemblyName>AdoCore</AssemblyName>
```

## 9. Publish the Application

Once validation is complete, publish a self-contained or framework-dependent release build:

**Framework-dependent:**
```bash
dotnet publish -c Release -o ./publish
```

**Self-contained (example for Linux x64):**
```bash
dotnet publish -c Release -r linux-x64 --self-contained true -o ./publish
```

Verify the contents of the `./publish` directory and confirm the application runs from that location before distributing it.