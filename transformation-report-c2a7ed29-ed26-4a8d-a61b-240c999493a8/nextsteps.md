# Next Steps

The solution appears to have transformed successfully — no build errors were detected across any of the projects in the solution.

## Validation Steps

### 1. Verify Target Framework
Open each `.csproj` file and confirm the `<TargetFramework>` (or `<TargetFrameworks>`) element is set to the intended cross-platform .NET version, for example:

```xml
<TargetFramework>net8.0</TargetFramework>
```

Ensure no projects are still referencing `net48` or other Windows-only framework monikers unless that is intentional.

### 2. Restore Dependencies
Run the following command from the solution root to confirm all NuGet packages resolve correctly:

```bash
dotnet restore
```

Review the output for any warnings about deprecated packages or packages that do not support the target framework.

### 3. Build the Solution
Perform a full build to confirm there are no errors or warnings that may have been suppressed during transformation:

```bash
dotnet build --configuration Release
```

Address any warnings that surface, particularly those related to nullable reference types or platform compatibility (`CA1416`).

### 4. Run Existing Tests
If the solution contains test projects, execute them to verify that existing behavior has been preserved:

```bash
dotnet test --configuration Release --logger "console;verbosity=detailed"
```

Review any failing tests carefully, as failures may indicate behavioral differences between .NET Framework and cross-platform .NET.

### 5. Check for Windows-Specific API Usage
Use the .NET Upgrade Assistant compatibility analyzer or the `Microsoft.DotNet.PlatformAbstractions` tooling to scan for APIs that are Windows-only. You can also run:

```bash
dotnet build /p:EnableNETAnalyzers=true /p:AnalysisMode=All
```

Pay close attention to `CA1416` warnings, which flag platform-specific API calls that will not work on Linux or macOS.

### 6. Verify Runtime Behavior on Target Platforms
If cross-platform support is a goal, run the application on each intended operating system (Windows, Linux, macOS) to confirm there are no runtime exceptions related to file paths, registry access, or other platform-specific behaviors.

```bash
dotnet run --configuration Release
```

### 7. Review Removed or Changed APIs
Cross-platform .NET removes certain APIs that existed in .NET Framework, such as:
- `System.Web` (use ASP.NET Core equivalents if applicable)
- `BinaryFormatter` (consider `System.Text.Json` or `System.Runtime.Serialization`)
- `AppDomain.CreateDomain`

Search the codebase for usages of these APIs and replace them with supported alternatives if any were carried over.

### 8. Publish the Application
Once validation is complete, publish the application for the target runtime:

```bash
dotnet publish --configuration Release --runtime linux-x64 --self-contained false
```

Replace `linux-x64` with the appropriate runtime identifier (`win-x64`, `osx-x64`, etc.) as needed. Review the publish output directory to confirm all required assets are present.