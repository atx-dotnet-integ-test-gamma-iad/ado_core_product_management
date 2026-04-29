# Next Steps

The transformation appears to have completed successfully. No build errors were detected across any of the projects in the solution. Below are recommended steps to validate and deploy your migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the target framework moniker (TFM) is set to your intended cross-platform target, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure this aligns with the .NET SDK version you have installed. Run the following to confirm your SDK version:

```bash
dotnet --version
```

## 2. Restore Dependencies

Run a full NuGet restore to ensure all packages resolve correctly against the new TFM:

```bash
dotnet restore
```

Review the output for any dependency warnings, particularly around packages that may have been resolved to older or incompatible versions.

## 3. Build the Solution

Perform a clean build to confirm there are no issues introduced by the restored packages:

```bash
dotnet build --configuration Release
```

Address any warnings that surface, particularly `NU1701` (package targeting warnings) or `CS0618` (obsolete API usage), as these may indicate areas that need further attention.

## 4. Run Existing Tests

If the solution contains test projects, execute them to verify that existing functionality behaves as expected under the new runtime:

```bash
dotnet test --configuration Release
```

Review any failing tests carefully, as failures may point to behavioral differences between .NET Framework and modern .NET (e.g., changes in `System.Data`, threading, or globalization).

## 5. Check for Platform-Specific API Usage

Use the .NET Upgrade Assistant compatibility analyzer or the `Microsoft.DotNet.PlatformAbstractions` tooling to scan for any remaining Windows-specific API calls that may not behave correctly on Linux or macOS:

```bash
dotnet tool install -g dotnet-compatibility
```

Pay particular attention to areas such as:
- `System.Data` and ADO.NET provider registration (relevant given the `AdoCore` project name)
- Registry access (`Microsoft.Win32.Registry`)
- Windows-specific file path assumptions

## 6. Validate ADO.NET Provider Configuration

Since this project appears to be ADO.NET related, confirm that any database providers (e.g., `System.Data.SqlClient` or `Microsoft.Data.SqlClient`) have been updated to their cross-platform compatible NuGet packages. `System.Data.SqlClient` should be replaced with `Microsoft.Data.SqlClient` if it has not been already:

```xml
<PackageReference Include="Microsoft.Data.SqlClient" Version="5.2.1" />
```

Update any `using` directives and connection factory references accordingly.

## 7. Test on Target Platforms

Run the application on each platform you intend to support (Windows, Linux, macOS) to surface any runtime issues that do not appear at compile time:

```bash
dotnet run --configuration Release
```

## 8. Publish the Application

Once validation is complete, publish the application for your target runtime:

```bash
dotnet publish --configuration Release --runtime linux-x64 --self-contained false
```

Adjust the `--runtime` identifier and `--self-contained` flag to match your deployment requirements. Common runtime identifiers include `win-x64`, `linux-x64`, and `osx-x64`.